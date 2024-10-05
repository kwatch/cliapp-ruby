# -*- coding: utf-8 -*-


PROJECT       = "cliapp"
COPYRIGHT     = "copyright(c) 2024 kwatch@gmail.com"

RUBY_VERSIONS = %w[3.3 3.2 3.1 3.0 2.7 2.6 2.5 2.4]

Dir.glob("./task/*-task.rb").each {|x| require x }
