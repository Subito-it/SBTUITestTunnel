#!/usr/bin/env ruby
require 'minitest/autorun'
require 'minitest/mock'
require 'tmpdir'
require_relative 'build_lib'

class BuildTest < Minitest::Test
  def setup
    @devices = {
      'com.apple.CoreSimulator.SimRuntime.iOS-18-4' => [device('iPhone 14', 'older-phone')],
      'com.apple.CoreSimulator.SimRuntime.iOS-26-1' => [device('iPhone 17', 'previous-phone')],
      'com.apple.CoreSimulator.SimRuntime.iOS-26-2' => [
        device('iPhone 17', 'unavailable-phone', false),
        device('iPhone 17', 'newest-phone'),
        device('iPad Pro', 'newest-ipad')
      ],
      'com.apple.CoreSimulator.SimRuntime.tvOS-27-0' => [device('Apple TV', 'tv')]
    }
  end

  def test_default_destination_uses_newest_ios_runtime_and_udid
    Build.stub(:simulator_devices, @devices) do
      assert_equal 'platform=iOS Simulator,id=newest-phone', Build.make_destination
    end
  end

  def test_multiscene_destination_selects_ipad_on_newest_ios_runtime
    Build.stub(:simulator_devices, @devices) do
      assert_equal 'platform=iOS Simulator,id=newest-ipad', Build.make_destination(family: 'iPad')
    end
  end

  def test_explicit_name_and_os_prefix_select_available_udid
    Build.stub(:simulator_devices, @devices) do
      assert_equal 'older-phone', Build.available_simulators('iPhone', 'iPhone 14')
      assert_equal 'previous-phone', Build.available_simulators('iPhone', 'iPhone 17', '26.1')
      assert_equal 'newest-phone', Build.available_simulators('iPhone', 'iPhone 17', '26')
    end
  end

  def test_unavailable_explicit_name_does_not_fall_back_to_another_device
    Build.stub(:simulator_devices, @devices) do
      error = assert_raises(RuntimeError) { Build.available_simulators('iPhone', 'iPhone 14', '26') }
      assert_includes error.message, 'No available iOS simulator runtime'
      assert_raises(RuntimeError) { Build.available_simulators('iPhone', nil, '26.3') }
    end
  end

  def test_runtime_versions_are_compared_numerically
    @devices['com.apple.CoreSimulator.SimRuntime.iOS-26-10'] = [device('iPhone 17', 'newest-minor')]
    Build.stub(:simulator_devices, @devices) do
      assert_equal 'newest-minor', Build.available_simulators
    end
  end

  def test_only_the_requested_result_bundle_is_removed
    Dir.mktmpdir('sbt-build-test') do |directory|
      Dir.chdir(directory) do
        FileUtils.mkdir_p('SwiftUI.xcresult')
        FileUtils.mkdir_p('SwiftUI-keep.xcresult')
        assert_equal 'SwiftUI.xcresult', Build.make_result_bundle_path('SwiftUI')
        refute File.exist?('SwiftUI.xcresult')
        assert File.directory?('SwiftUI-keep.xcresult')
      end
    end
  end

  def test_pipeline_preserves_build_failure_and_quotes_paths_and_schemes
    invocation = nil
    Build.stub(:make_destination, 'platform=iOS Simulator,id=test-udid') do
      Build.stub(:make_result_bundle_path, 'My Scheme.xcresult') do
        Build.stub(:system, ->(*arguments) { invocation = arguments; false }) do
          refute Build.run_xcodebuild('build-for-testing', 'Project Folder/App.xcodeproj', 'My Scheme')
        end
      end
    end
    assert_equal ['/bin/bash', '-o', 'pipefail', '-c'], invocation.first(4)
    command = invocation.last.delete_suffix(' | xcpretty')
    arguments = Shellwords.split(command)
    assert_equal 'Project Folder/App.xcodeproj', arguments[arguments.index('-project') + 1]
    assert_equal 'My Scheme', arguments[arguments.index('-scheme') + 1]
    assert_equal 'My Scheme.xcresult', arguments[arguments.index('-resultBundlePath') + 1]
  end

  def test_multiscene_wrapper_keeps_ipad_family
    invocation = nil
    Build.stub(:run_xcodebuild, ->(*arguments, **options) { invocation = [arguments, options]; true }) do
      assert Build.run_ui_tests_multiscene('Examples/UIKit/SBTUITestTunnel.xcworkspace')
    end
    assert_equal ['test', 'Examples/UIKit/SBTUITestTunnel.xcworkspace', 'MultiSceneExample'], invocation.first
    assert_equal({family: 'iPad'}, invocation.last)
  end

  def test_build_ui_tests_uses_requested_derived_data_path
    invocation = nil
    Build.stub(:make_destination, 'platform=iOS Simulator,id=test-udid') do
      Build.stub(:system, ->(*arguments) { invocation = arguments; true }) do
        assert Build.build_ui_tests('App.xcworkspace', 'My Scheme', derived_data_path: 'Derived Data')
      end
    end
    arguments = Shellwords.split(invocation.last.delete_suffix(' | xcpretty'))
    assert_equal 'build-for-testing', arguments[1]
    assert_equal 'Derived Data', arguments[arguments.index('-derivedDataPath') + 1]
  end

  def test_prebuilt_ui_tests_run_the_scheme_xctestrun_on_requested_family
    Dir.mktmpdir('sbt-build-test') do |products|
      xctestrun = File.join(products, 'MultiSceneExample_iphonesimulator26.2-arm64.xctestrun')
      FileUtils.touch(xctestrun)
      FileUtils.touch(File.join(products, 'MultiSceneExample_Other_iphonesimulator26.2-arm64.xctestrun'))
      invocation = nil
      family = nil
      Build.stub(:make_destination, ->(**options) { family = options[:family]; 'platform=iOS Simulator,id=ipad' }) do
        Build.stub(:system, ->(*arguments) { invocation = arguments; true }) do
          assert Build.run_ui_tests_without_building(products, 'MultiSceneExample', family: 'iPad')
        end
      end
      arguments = Shellwords.split(invocation.last.delete_suffix(' | xcpretty'))
      assert_equal 'iPad', family
      assert_equal 'test-without-building', arguments[1]
      assert_equal xctestrun, arguments[arguments.index('-xctestrun') + 1]
      refute_includes arguments, '-scheme'
      assert_equal 'MultiSceneExample.xcresult', arguments[arguments.index('-resultBundlePath') + 1]
    end
  end

  def test_missing_xctestrun_fails_with_scheme_name
    Dir.mktmpdir('sbt-build-test') do |products|
      error = assert_raises(RuntimeError) { Build.find_xctestrun(products, 'SBTUITestTunnel_Tests') }
      assert_includes error.message, 'SBTUITestTunnel_Tests'
    end
  end

  private

  def device(name, udid, available = true)
    { 'name' => name, 'udid' => udid, 'isAvailable' => available }
  end
end
