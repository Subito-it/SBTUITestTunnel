#!/usr/bin/env ruby
require "fileutils"

module Build
  UITESTS_SCHEME = "UIKit"
  UITESTS_NOSWIZZ_SCHEME = "UIKit_NoSwizzling_Tests"
  SWIFTUI_UITESTS_SCHEME = "SwiftUI"

  # Configurable UI Test Retry Settings
  # Can be overridden by environment variables:
  # - TEST_RETRY_COUNT: Number of test iterations (default: 3)
  # - TEST_RETRY_ENABLED: Enable/disable retry on failure (default: true)
  TEST_RETRY_COUNT = ENV['TEST_RETRY_COUNT']&.to_i || 3
  TEST_RETRY_ENABLED = ENV['TEST_RETRY_ENABLED'] != 'false'

  def self.run_build(project_path, scheme)
    if scheme.nil? || scheme.empty?
      puts "❌ Error: Scheme parameter is required"
      puts "Usage: run_build(project_path, scheme)"
      return false
    end

    puts "⏳ Building scheme: #{scheme}"
    return run_xcodebuild("clean build", project_path, scheme)
  end

  def self.run_ui_tests(project_path)
    puts "⏳ Run UITests..."
    return run_xcodebuild("test", project_path, UITESTS_SCHEME)
  end

  def self.run_ui_tests_no_swizzling(project_path)
    puts "⏳ Run UITests with no swizzling..."
    return run_xcodebuild("test", project_path, UITESTS_NOSWIZZ_SCHEME)
  end

  def self.run_swiftui_ui_tests(project_path)
    puts "⏳ Run SwiftUI UITests..."
    return run_xcodebuild("test", project_path, SWIFTUI_UITESTS_SCHEME)
  end

  def self.run_xcodebuild(action, path, scheme_name)
    base_path = `git rev-parse --show-toplevel`.strip
    workspace = "#{base_path}/#{path}"
    destination = make_destination()
    project_type = path.end_with?(".xcworkspace") ? "workspace" : "project"
    result_bundle_path = make_result_bundle_path(scheme_name)

    # Build retry options based on configuration
    retry_options = ""
    if action.include?("test") && TEST_RETRY_ENABLED
      retry_options = "-retry-tests-on-failure -test-iterations #{TEST_RETRY_COUNT}"
      puts "🔄 UI Test retry configured: #{TEST_RETRY_COUNT} iterations, retry on failure enabled"
    elsif action.include?("test")
      puts "🔄 UI Test retry disabled"
    end

    command = "xcodebuild #{action} -scheme #{scheme_name} -#{project_type} #{path} -sdk iphonesimulator #{retry_options} -destination \"#{destination}\" -resultBundlePath \"#{result_bundle_path}\" | xcpretty && exit ${PIPESTATUS[0]}"
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
    destination = "platform=#{platform},#{device}"
    puts "🎯 Selected destination: '#{destination}'"
    return destination
  end

  def self.available_simulators()
    # Try to get a specific iPhone simulator with ID for more reliable targeting
    device_id = `xcrun simctl list devices available | grep "iPhone 12" | head -1 | grep -oE '\\([A-F0-9-]+\\)' | tr -d '()'`.strip
    if !device_id.empty?
      puts "📱 Selected simulator ID: '#{device_id}'"
      return "id=#{device_id}"
    else
      # Fallback to name-based selection
      device = `xcrun xctrace list devices 2>&1 | grep -oE 'iPhone.*?[^\(]+' | head -1 | awk '{$1=$1;print}' | sed -e "s/ Simulator$//"`.strip
      puts "📱 Selected simulator: '#{device}'"
      return "name=#{device}"
    end
  end
end
