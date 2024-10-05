# -*- coding: utf-8 -*-


task :default => :help    # or :test if you like


desc "list task names"
task :help do
  system "rake -T"
end


desc "show how to release"
task :howto, [:version] do |t, args|
  project = PROJECT
  version = args[:version] || ENV['version'] || "0.0.0"
  version =~ /\A(\d+\.\d+)/  or
    abort "#{version}: Invalid version number."
  ver = $1
  zero_p = ver.end_with?('.0')
  opt_b = zero_p ? " -b" : ""
  puts <<"END"
How to release:

  $ git diff            	# confirm that there is no changes
  $ rake test
  $ rake test:all       	# test on Ruby 2.x ~ 3.x
  $ git checkout#{opt_b} rel-#{ver}	# create or switch to release branch
  $ vi CHANGES.md       	# if necessary
  $ git add CHANGES.md       	# if necessary
  $ git commit -m "Update 'CHANGES.md'"	# if necessary
  $ git log -1          	# if necessary
  $ cid=$(git log -1 | awk 'NR==1{print $2}')	# if necessary
  $ rake prepare[#{version}] 	# update release number
  $ git add -u .        	# add changes
  $ git status -sb .    	# list files in staging area
  $ git diff --cache    	# confirm changes in staging area
  $ git commit -m "Preparation for release #{version}"
  $ proj=#{project}
  $ gem build $proj.gemspec	# build gem package
  $ gem unpack $proj-#{version}.gem	# extract gem package
  $ find $proj-#{version}       	# confirm file list in gem package
  $ rm -rf $proj-#{version}     	# remove files extracted
  $ gem push $proj-#{version}.gem	# release gem package
  $ git push -u origin rel-#{ver}
  $ git tag v#{version}         	# add version tag
  $ git push --tags
  $ git checkout -      	# back to main branch
  $ git log -1 $cid     	# if necessary
  $ git cherry-pick $cid	# if necessary
  $ git rm $proj-#{version}.gem 	# if necessary

END
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
