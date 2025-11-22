#!/usr/bin/env ruby
require "fileutils"

module Build
  UITESTS_SCHEME = "UIKit"
  UITESTS_NOSWIZZ_SCHEME = "UIKit_NoSwizzlingTests"
  SWIFTUI_UITESTS_SCHEME = "SwiftUI"
  IPHONE = "iPhone 17"

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

  # Generalized build function for any scheme
  def self.build_ui_tests(project_path, scheme)
    if scheme.nil? || scheme.empty?
      puts "❌ Error: Scheme parameter is required"
      puts "Usage: build_ui_tests(project_path, scheme)"
      return false
    end

    puts "🔨 Build UITests Bundle for scheme: #{scheme}..."

    # Build for testing (creates cached test bundle)
    puts "   → Building test bundle for caching..."
    return run_xcodebuild("build-for-testing", project_path, scheme)
  end

  # Generalized test function for any scheme (uses cached build)
  def self.run_ui_tests_with_cached_build(project_path, scheme)
    if scheme.nil? || scheme.empty?
      puts "❌ Error: Scheme parameter is required"
      puts "Usage: run_ui_tests_with_cached_build(project_path, scheme)"
      return false
    end

    clean_simulators()

    puts "🧪 Run UITests with Cached Build for scheme: #{scheme}..."

    # Run tests using cached build from previous step
    puts "   → Running tests with cached build..."
    return run_xcodebuild("test-without-building", project_path, scheme)
  end

  # Legacy SwiftUI-specific functions (for backward compatibility)
  def self.build_swiftui_ui_tests(project_path)
    return build_ui_tests(project_path, SWIFTUI_UITESTS_SCHEME)
  end

  def self.run_swiftui_ui_tests_with_cached_build(project_path)
    return run_ui_tests_with_cached_build(project_path, SWIFTUI_UITESTS_SCHEME)
  end

  def self.run_swiftui_ui_tests(project_path)
    puts "⏳ Run SwiftUI UITests (Combined Build + Test)..."

    # Phase 1: Build for testing
    build_success = build_swiftui_ui_tests(project_path)

    unless build_success
      puts "❌ Build phase failed, skipping test execution"
      return false
    end

    puts "✅ Build phase completed successfully"

    # Phase 2: Run tests using cached build
    return run_swiftui_ui_tests_with_cached_build(project_path)
  end

  def self.run_xcodebuild(action, path, scheme_name)
    if path.nil? || path.empty?
      puts "❌ Error: Project path parameter is required"
      puts "Usage: run_xcodebuild(action, project_path, scheme)"
      return false
    end

    base_path = `git rev-parse --show-toplevel`.strip
    workspace = "#{base_path}/#{path}"
    destination = make_destination()
    project_type = path.end_with?(".xcworkspace") ? "workspace" : "project"
    result_bundle_path = make_result_bundle_path(scheme_name)

    # Build retry options based on configuration
    retry_options = ""
    if action.include?("test") && !action.include?("build-for-testing") && TEST_RETRY_ENABLED
      retry_options = "-retry-tests-on-failure -test-iterations #{TEST_RETRY_COUNT}"
      puts "🔄 UI Test retry configured: #{TEST_RETRY_COUNT} iterations, retry on failure enabled"
    elsif action.include?("test") && !action.include?("build-for-testing")
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
    device_id = `xcrun simctl list devices available | grep "#{IPHONE}" | head -1 | grep -oE '\\([A-F0-9-]+\\)' | tr -d '()'`.strip
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

  def self.clean_simulators()
    puts "🧹 Cleaning simulators to avoid CI hanging issues..."

    # Shutdown all simulators
    puts "   → ⬇️ Shutting down all simulators..."
    system("xcrun simctl shutdown all")
    sleep(5)

    puts "   → ✏️ Erasing all simulators..."
    system("xcrun simctl erase all")
    sleep(5)

    puts "✅ Simulator cleanup completed"
  end
end
