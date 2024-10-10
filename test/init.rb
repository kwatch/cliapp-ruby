# encoding: utf-8
# frozen_string_literal: true

require 'oktest'

testdir = File.dirname(__FILE__)
libdir  = File.absolute_path(File.join(File.dirname(testdir), "lib"))
$LOAD_PATH << libdir unless $LOAD_PATH.include?(libdir)

require 'cliapp'


Oktest.global_scope do

end
