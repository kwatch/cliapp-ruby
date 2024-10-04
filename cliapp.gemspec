# -*- coding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.name            = 'cliapp'
  spec.version         = '$Version: 0.0.0 $'.split()[1]
  spec.author          = 'kwatch'
  spec.email           = 'kwatch@gmail.com'
  spec.platform        = Gem::Platform::RUBY
  spec.homepage        = 'https://github.com/kwatch/cliapp-ruby'
  spec.summary         = "CLI Application Framework"
  spec.description     = <<-'END'
A small framework for CLI Applications such as Git, Docker, NPM, etc.
END
  spec.license         = 'MIT'
  spec.files           = Dir[*%w[
                           README.md MIT-LICENSE Rakefile.rb cliapp.gemspec
                           lib/**/*.rb
                           test/**/*.rb
                           task/**/*.rb
                         ]]
  spec.executables     = ['hello']
  spec.bindir          = 'bin'
  spec.require_path    = 'lib'
  spec.test_files      = Dir['test/**/*_test.rb']
  #spec.extra_rdoc_files = ['README.md', 'CHANGES.md']

  spec.required_ruby_version = ">= 2.4"
  spec.add_development_dependency 'oktest', '~> 1.4'
end
