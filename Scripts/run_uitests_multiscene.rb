#!/usr/bin/env ruby
require_relative 'build_lib'

abort "Usage: #{File.basename($0)} <project_path>" unless ARGV.length == 1
exit Build.run_ui_tests_multiscene(ARGV[0]) ? 0 : 1
