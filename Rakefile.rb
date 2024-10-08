# coding: utf-8
# frozen_string_literal: true


PROJECT       = "cliapp"
COPYRIGHT     = "copyright(c) 2024 kwatch@gmail.com"

RUBY_VERSIONS = %w[3.3 3.2 3.1 3.0 2.7 2.6 2.5 2.4]  # for 'test:all' task

task :default => :help   # or :test if you prefer

require_relative "./rake/init"
Dir.glob("./rake/*_task.rb").sort.each {|x| require x }
