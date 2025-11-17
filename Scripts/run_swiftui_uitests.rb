#!/usr/bin/env ruby
require_relative "build_lib"
exit Build.run_swiftui_ui_tests_with_cached_build(ARGV[0])