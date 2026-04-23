#!/usr/bin/env ruby
require 'fileutils'

module Build
  def self.build_app(project_path, scheme, simulator_name = nil, simulator_os = nil)
    puts "⏳ Building app for scheme '#{scheme}'..."
    run_xcodebuild('clean build', project_path, scheme, simulator_name, simulator_os)
  end

  def self.build_ui_tests(project_path, scheme, simulator_name = nil, simulator_os = nil)
    puts "⏳ Building UI tests for scheme '#{scheme}'..."
    run_xcodebuild('build-for-testing', project_path, scheme, simulator_name, simulator_os)
  end

  def self.run_ui_tests(project_path, scheme, simulator_name = nil, simulator_os = nil)
    puts "⏳ Running UI tests for scheme '#{scheme}'..."
    run_xcodebuild('test', project_path, scheme, simulator_name, simulator_os)
  end

  def self.run_xcodebuild(action, path, scheme_name, simulator_name = nil, simulator_os = nil)
    `git rev-parse --show-toplevel`.strip
    destination = make_destination(simulator_name, simulator_os)
    project_type = path.end_with?('.xcworkspace') ? 'workspace' : 'project'
    result_bundle_path = make_result_bundle_path(scheme_name)
    command = "xcodebuild #{action} -scheme #{scheme_name} -#{project_type} #{path} -sdk iphonesimulator -retry-tests-on-failure -test-iterations 3 -destination \"#{destination}\" -resultBundlePath \"#{result_bundle_path}\" | xcpretty && exit ${PIPESTATUS[0]}"
    result = system(command)
    if result
      puts 'XcodeBuild status: ✅ SUCCESS'
    else
      puts 'XcodeBuild status: 🚨 FAILED'
    end
    result
  end

  def self.make_result_bundle_path(scheme_name)
    bundle_files = Dir.glob("#{scheme_name}*.xcresult")
    unless bundle_files.empty?
      puts "🧹 Delete result bundle files: '#{bundle_files}'"
      FileUtils.rm_r(bundle_files)
    end
    "#{scheme_name}.xcresult"
  end

  def self.make_destination(simulator_name = nil, simulator_os_prefix = nil)
    platform = 'iOS Simulator'
    if simulator_name && simulator_os_prefix
      os_version = find_matching_os_version(simulator_name, simulator_os_prefix)
      if os_version
        destination = "platform=#{platform},name=#{simulator_name},OS=#{os_version}"
        puts "🎯 Using destination: '#{destination}'"
      else
        puts "⚠️ No simulator found for #{simulator_name} with iOS #{simulator_os_prefix}.x, falling back to auto-detect"
        device = detect_simulator
        destination = "platform=#{platform},name=#{device}"
        puts "🎯 Auto-detected destination: '#{destination}'"
      end
    else
      device = detect_simulator
      destination = "platform=#{platform},name=#{device}"
      puts "🎯 Auto-detected destination: '#{destination}'"
    end
    destination
  end

  def self.find_matching_os_version(simulator_name, os_prefix)
    # List all available simulators and find matching OS versions
    output = `xcrun simctl list devices available -j 2>/dev/null`
    require 'json'
    begin
      devices = JSON.parse(output)['devices']
      matching_versions = []

      devices.each do |runtime, device_list|
        # runtime format: "com.apple.CoreSimulator.SimRuntime.iOS-18-4"
        next unless runtime.include?('iOS')

        # Extract version from runtime string
        version_match = runtime.match(/iOS[.-](\d+)[.-](\d+)/)
        next unless version_match

        major = version_match[1]
        minor = version_match[2]
        version = "#{major}.#{minor}"

        # Check if this runtime has our simulator and matches the prefix
        next unless major == os_prefix.to_s || version.start_with?(os_prefix.to_s)

        has_simulator = device_list.any? { |d| d['name'] == simulator_name && d['isAvailable'] }
        matching_versions << version if has_simulator
      end

      # Sort versions and return the highest one
      if matching_versions.any?
        highest = matching_versions.sort_by { |v| v.split('.').map(&:to_i) }.last
        puts "📱 Found #{simulator_name} with iOS #{highest} (matching prefix #{os_prefix})"
        return highest
      end
    rescue => e
      puts "⚠️ Error parsing simulators: #{e.message}"
    end
    nil
  end

  def self.detect_simulator
    device = `xcrun xctrace list devices 2>&1 | grep -oE 'iPhone.*?[^\(]+' | head -1 | awk '{$1=$1;print}' | sed -e "s/ Simulator$//"`.strip
    puts "📱 Auto-detected simulator: '#{device}'"
    device
  end
end
