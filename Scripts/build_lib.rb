#!/usr/bin/env ruby
require "fileutils"

module Build
  EXAMPLE_APP_SCHEME = "SBTUITestTunnel"
  UITESTS_SCHEME = "SBTUITestTunnel_Tests"
  UITESTS_NOSWIZZ_SCHEME = "SBTUITestTunnel_NoSwizzlingTests"

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

  def self.run_xcodebuild(action, path, scheme_name)
    base_path = `git rev-parse --show-toplevel`.strip
    workspace = "#{base_path}/#{path}"
    destination = make_destination()
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

  def self.make_destination()
    platform = "iOS Simulator"
    device = available_simulators()
    destination = "platform=#{platform},name=#{device}"
    puts "🎯 Selected destination: '#{destination}'"
    return destination
  end

  def self.available_simulators()
    device = `xcrun xctrace list devices 2>&1 | grep -oE 'iPhone.*?[^\(]+' | head -1 | awk '{$1=$1;print}' | sed -e "s/ Simulator$//"`.strip
    puts "📱 Selected simulator: '#{device}'"
    return device
  end
end
