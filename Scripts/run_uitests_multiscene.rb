#!/usr/bin/env ruby
require_relative "build_lib"
exit Build.run_ui_tests_multiscene(ARGV[0])
