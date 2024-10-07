# -*- coding: utf-8 -*-
# frozen_string_literal: true

require_relative './init'

path = File.dirname(__FILE__)
Dir.glob(path + '/**/*_test.rb').sort.each do |file|
  require_relative file.sub(path, '.')
end


if __FILE__ == $0
  require 'oktest'
  Oktest.module_eval do
    if defined?(REPORTER_CLASS)       # Oktest < 1.5
      remove_const :REPORTER_CLASS
      const_set :REPORTER_CLASS, Oktest::PlainReporter
    else                              # Oktst >= 1.5
      self.DEFAULT_REPORTING_STYLE = "plain"
    end
  end
end
