#!/usr/bin/env ruby
require_relative "build_lib"
exit Build.run_ui_tests_no_swizzling(ARGV[0])
