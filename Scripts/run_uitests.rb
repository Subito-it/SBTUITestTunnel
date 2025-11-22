#!/usr/bin/env ruby
require_relative "build_lib"

if ARGV.length != 2
  puts "❌ Usage: #{File.basename($0)} <project_path> <scheme>"
  puts "Examples:"
  puts "  #{File.basename($0)} Examples/SwiftUI/SBTUITestTunnel_SwiftUI.xcodeproj SwiftUI"
  puts "  #{File.basename($0)} Examples/UIKit/SBTUITestTunnel_UIKit.xcworkspace UIKit"
  puts "  #{File.basename($0)} Examples/UIKit/SBTUITestTunnel_UIKit.xcworkspace UIKit_NoSwizzlingTests"
  exit 1
end

project_path = ARGV[0]
scheme = ARGV[1]

exit Build.run_ui_tests_with_cached_build(project_path, scheme)