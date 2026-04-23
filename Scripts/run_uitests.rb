#!/usr/bin/env ruby
require_relative 'build_lib'

if ARGV.length < 2
  puts "❌ Usage: #{File.basename($0)} <project_path> <scheme> [simulator_name] [simulator_os]"
  puts 'Examples:'
  puts "  #{File.basename($0)} Examples/UIKit/SBTUITestTunnel.xcworkspace UIKit_Tests"
  puts "  #{File.basename($0)} Examples/SwiftUI/SBTUITestTunnel_SwiftUI.xcodeproj SwiftUI"
  puts "  #{File.basename($0)} Examples/SwiftUI/SBTUITestTunnel_SwiftUI.xcodeproj SwiftUI 'iPhone 16' '18.0'"
  exit 1
end

project_path = ARGV[0]
scheme = ARGV[1]
simulator_name = ARGV[2]
simulator_os = ARGV[3]

exit Build.run_ui_tests(project_path, scheme, simulator_name, simulator_os) ? 0 : 1
