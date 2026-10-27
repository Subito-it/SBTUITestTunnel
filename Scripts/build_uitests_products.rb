#!/usr/bin/env ruby
require_relative 'build_lib'

if ARGV.length < 3
  puts "❌ Usage: #{File.basename($0)} <project_path> <derived_data_path> <scheme> [scheme...]"
  puts 'Example:'
  puts "  #{File.basename($0)} Examples/UIKit/SBTUITestTunnel.xcworkspace DerivedData SBTUITestTunnel_Tests MultiSceneExample"
  exit 1
end

project_path, derived_data_path, *schemes = ARGV

success = schemes.all? do |scheme|
  Build.build_ui_tests(project_path, scheme, derived_data_path: derived_data_path)
end
exit success ? 0 : 1
