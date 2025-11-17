#!/usr/bin/env ruby
require_relative "build_lib"
exit Build.build_swiftui_ui_tests(ARGV[0])