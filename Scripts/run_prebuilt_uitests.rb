#!/usr/bin/env ruby
require_relative 'build_lib'

unless [2, 3].include?(ARGV.length)
  puts "❌ Usage: #{File.basename($0)} <products_path> <scheme> [iPhone|iPad]"
  puts 'Example:'
  puts "  #{File.basename($0)} DerivedData/Build/Products MultiSceneExample iPad"
  exit 1
end

products_path, scheme, family = ARGV

exit Build.run_ui_tests_without_building(products_path, scheme, family: family || 'iPhone') ? 0 : 1
