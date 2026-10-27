#!/usr/bin/env ruby
require 'fileutils'
require 'json'
require 'open3'
require 'shellwords'

module Build
  EXAMPLE_APP_SCHEME = 'SBTUITestTunnel'
  UITESTS_SCHEME = 'SBTUITestTunnel_Tests'
  UITESTS_NOSWIZZ_SCHEME = 'SBTUITestTunnel_NoSwizzlingTests'
  UITESTS_MULTISCENE_SCHEME = 'MultiSceneExample'

  def self.build_app(project_path, scheme = EXAMPLE_APP_SCHEME, simulator_name = nil, simulator_os = nil)
    puts "⏳ Building app for scheme '#{scheme}'..."
    run_xcodebuild('clean build', project_path, scheme, simulator_name, simulator_os)
  end

  def self.build_ui_tests(project_path, scheme = UITESTS_SCHEME, simulator_name = nil, simulator_os = nil)
    puts "⏳ Building UI tests for scheme '#{scheme}'..."
    run_xcodebuild('build-for-testing', project_path, scheme, simulator_name, simulator_os)
  end

  def self.run_ui_tests(project_path, scheme = UITESTS_SCHEME, simulator_name = nil, simulator_os = nil)
    puts "⏳ Running UI tests for scheme '#{scheme}'..."
    run_xcodebuild('test', project_path, scheme, simulator_name, simulator_os)
  end

  def self.run_build(project_path)
    build_app(project_path)
  end

  def self.run_ui_tests_no_swizzling(project_path)
    run_ui_tests(project_path, UITESTS_NOSWIZZ_SCHEME)
  end

  # iOS only creates additional application windows on iPad. Keep these tests
  # on an iPad so the multi-window assertions run instead of being skipped.
  def self.run_ui_tests_multiscene(project_path)
    run_xcodebuild('test', project_path, UITESTS_MULTISCENE_SCHEME, family: 'iPad')
  end

  def self.run_xcodebuild(action, path, scheme_name, simulator_name = nil, simulator_os = nil, family: 'iPhone')
    destination = make_destination(simulator_name, simulator_os, family: family)
    project_type = path.end_with?('.xcworkspace') ? '-workspace' : '-project'
    result_bundle_path = make_result_bundle_path(scheme_name)
    command = ['xcodebuild', *Shellwords.split(action), '-scheme', scheme_name,
               project_type, path, '-sdk', 'iphonesimulator', '-retry-tests-on-failure',
               '-test-iterations', '5', '-destination', destination,
               '-resultBundlePath', result_bundle_path]
    # Preserve xcodebuild failures even if xcpretty exits successfully.
    result = system('/bin/bash', '-o', 'pipefail', '-c', "#{Shellwords.join(command)} | xcpretty")
    puts result ? 'XcodeBuild status: ✅ SUCCESS' : 'XcodeBuild status: 🚨 FAILED'
    result
  end

  def self.make_result_bundle_path(scheme_name)
    result_bundle_path = "#{scheme_name}.xcresult"
    if File.exist?(result_bundle_path)
      puts "🧹 Delete result bundle: '#{result_bundle_path}'"
      FileUtils.rm_r(result_bundle_path)
    end
    result_bundle_path
  end

  def self.make_destination(simulator_name = nil, simulator_os_prefix = nil, family: 'iPhone')
    udid = available_simulators(family, simulator_name, simulator_os_prefix)
    destination = "platform=iOS Simulator,id=#{udid}"
    puts "🎯 Selected destination: '#{destination}'"
    destination
  end

  def self.simulator_devices
    output, status = Open3.capture2e('xcrun', 'simctl', 'list', 'devices', 'available', '--json')
    raise "Unable to list available simulators: #{output}" unless status.success?

    JSON.parse(output).fetch('devices')
  end

  def self.available_simulators(family = 'iPhone', simulator_name = nil, os_prefix = nil)
    # Runners retain devices for multiple runtimes. Select the newest matching
    # iOS runtime explicitly, then use a UDID so a device name cannot silently
    # resolve against a different runtime through OS:latest.
    devices = simulator_devices
    runtimes = devices.keys.select do |runtime|
      version = runtime[/SimRuntime\.iOS-([\d-]+)\z/, 1]
      next false unless version
      next false if devices[runtime].none? do |device|
        device['isAvailable'] != false && (!simulator_name || device['name'] == simulator_name)
      end

      !os_prefix || version.split('-').first(os_prefix.to_s.split('.').length).join('.') == os_prefix.to_s
    end
    newest_runtime = runtimes.max_by { |runtime| runtime[/iOS-([\d-]+)/, 1].split('-').map(&:to_i) }
    raise "No available iOS simulator runtime found#{os_prefix ? " matching #{os_prefix}" : ''}" unless newest_runtime

    device = devices[newest_runtime].find do |candidate|
      candidate['isAvailable'] != false &&
        (simulator_name ? candidate['name'] == simulator_name : candidate['name'].start_with?(family))
    end
    raise "No available #{simulator_name || family} simulator found on #{newest_runtime}" unless device

    ios_version = newest_runtime[/iOS-([\d-]+)/, 1].tr('-', '.')
    puts "📱 Selected simulator: '#{device['name']}' (iOS #{ios_version})"
    device.fetch('udid')
  end
end
