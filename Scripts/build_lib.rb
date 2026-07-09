#!/usr/bin/env ruby
require "fileutils"

module Build
  EXAMPLE_APP_SCHEME = "SBTUITestTunnel"
  UITESTS_SCHEME = "SBTUITestTunnel_Tests"
  UITESTS_NOSWIZZ_SCHEME = "SBTUITestTunnel_NoSwizzlingTests"
  UITESTS_SCENE_SCHEME = "SceneExample"

  def self.run_build(project_path)
    puts "⏳ Building app..."
    return run_xcodebuild("clean build", project_path, EXAMPLE_APP_SCHEME)
  end

  def self.run_ui_tests(project_path)
    puts "⏳ Run UITests..."
    return run_xcodebuild("test", project_path, UITESTS_SCHEME)
  end

  def self.run_ui_tests_no_swizzling(project_path)
    puts "⏳ Run UITests with no swizzling..."
    return run_xcodebuild("test", project_path, UITESTS_NOSWIZZ_SCHEME)
  end

  # The scene lifecycle tests exercise the multi-window path, which iOS only
  # materialises on iPad. Run them against an iPad so both the launch-ordering
  # test (device-agnostic) and the multi-scene test actually execute.
  def self.run_ui_tests_scene(project_path)
    puts "⏳ Run SceneDelegate UITests..."
    return run_xcodebuild("test", project_path, UITESTS_SCENE_SCHEME, family: "iPad")
  end

  def self.run_xcodebuild(action, path, scheme_name, family: "iPhone")
    base_path = `git rev-parse --show-toplevel`.strip
    workspace = "#{base_path}/#{path}"
    destination = make_destination(family)
    project_type = path.end_with?(".xcworkspace") ? "workspace" : "project"
    result_bundle_path = make_result_bundle_path(scheme_name)
    command = "xcodebuild #{action} -scheme #{scheme_name} -#{project_type} #{path} -sdk iphonesimulator -retry-tests-on-failure -test-iterations 5 -destination \"#{destination}\" -resultBundlePath \"#{result_bundle_path}\" | xcpretty && exit ${PIPESTATUS[0]}"
    result = system(command)
    if result
      puts "XcodeBuild status: ✅ SUCCESS"
    else
      puts "XcodeBuild status: 🚨 FAILED"
    end
    return result
  end

  def self.make_result_bundle_path(scheme_name)
    bundle_files = Dir.glob("#{scheme_name}*")
    if !bundle_files.empty?
      puts "🧹 Delete result bundle files: '#{bundle_files}'"
      FileUtils.rm_r(bundle_files)
    end
    return "#{scheme_name}.xcresult"
  end

  def self.make_destination(family = "iPhone")
    platform = "iOS Simulator"
    udid = available_simulators(family)
    destination = "platform=#{platform},id=#{udid}"
    puts "🎯 Selected destination: '#{destination}'"
    return destination
  end

  def self.available_simulators(family = "iPhone")
    # Return the UDID of an *available* simulator of the requested family on the
    # newest installed iOS runtime. Selecting by UDID (rather than name) avoids
    # the ambiguity where a bare name resolves to OS:latest even though that
    # device exists only on an older runtime.
    #
    # The runtime must be chosen explicitly: runners keep multiple Xcodes (hence
    # multiple iOS runtimes) installed side by side, so a plain "first device"
    # scan can land on a stale runtime even after selecting a newer Xcode.
    # Always target the highest available iOS version.
    require "json"
    devices = JSON.parse(`xcrun simctl list devices available --json`)["devices"]

    newest_runtime = devices.keys
      .select { |id| id.include?("SimRuntime.iOS-") }
      .max_by { |id| id[/iOS-([\d-]+)/, 1].split("-").map(&:to_i) }
    raise "No available iOS simulator runtime found" unless newest_runtime

    device = (devices[newest_runtime] || []).find { |d| d["name"].start_with?(family) }
    raise "No available #{family} simulator found on #{newest_runtime}" unless device

    ios_version = newest_runtime[/iOS-([\d-]+)/, 1].tr("-", ".")
    puts "📱 Selected simulator: '#{device["name"]}' (iOS #{ios_version})"
    return device["udid"]
  end
end
