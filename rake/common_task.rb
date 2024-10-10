# encoding: utf-8
# frozen_string_literal: true


task :default => :help    # or :test if you like


desc "list task names"
task :help do
  system "rake -T"
end


desc "run test scripts"
task :test do
  $LOAD_PATH << File.join(File.dirname(__FILE__), "lib")
  sh "oktest test -sp"
end


desc "run test scripts on Ruby 2.x and 3.x"
task :'test:all' do
  vs_home = ENV['VS_HOME']  or raise "$VS_HOME should be set."
  defined?(RUBY_VERSIONS)  or raise "RUBY_VERSIONS should be defined."
  $LOAD_PATH << File.join(File.dirname(__FILE__), "lib")
  RUBY_VERSIONS.each do |ver|
    path_pat = "#{vs_home}/ruby/#{ver}.*/bin/ruby"
    ruby_path = Dir.glob(path_pat).sort.last()  or
      raise "#{path_pat}: Not exist."
    puts "\e[33m======== Ruby #{ver} ========\e[0m"
    sh "#{ruby_path} -r oktest -e 'Oktest.main' -- test -sp" do end
    puts ""
  end
end
