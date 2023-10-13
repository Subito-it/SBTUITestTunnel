#!/usr/bin/env ruby
require_relative "build_lib"
exit Build.run_ui_tests(ARGV[0])
