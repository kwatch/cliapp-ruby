# -*- coding: utf-8 -*-


desc "show how to release"
task "release:howto", [:version] do |t, args|
  puts _release_howto(PROJECT, args[:version])
end

def _release_howto(project, version)
  version ||= (ENV['version'] || "0.0.0")
  version =~ /\A(\d+\.\d+)/  or
    abort "#{version}: Invalid version number."
  ver = $1
  zero_p = ver.end_with?('.0')
  opt_b = zero_p ? " -b" : ""
  comm  = zero_p ? "create a new" : "switch to existing"
  return <<"END"
## How to release #{version}

git diff                	# confirm that there is no changes
rake test
rake test:all           	# test on Ruby 2.x ~ 3.x
git checkout#{opt_b} rel-#{ver}    	# #{comm} release branch
vi CHANGES.md
git add CHANGES.md
git commit -m "Update 'CHANGES.md'"
git log -1              	# confirm the commit
cid=$(git log -1 | awk 'NR==1{print $2}')  	# in order to cherry-pick later
rake prepare[#{version}]        	# update release number in files
git add -u .            	# add changes into staging area
git status -sb .        	# list files in staging area
git diff --cached       	# confirm changes in staging area
git commit -m "Preparation for release #{version}"
gem build #{project}.gemspec  	# build gem package
gem unpack #{project}-#{version}.gem 	# extract gem package
find #{project}-#{version}         	# confirm file list in gem package
rm -rf #{project}-#{version}       	# delete extracted files
gem push #{project}-#{version}.gem 	# release gem package
git push -u origin rel-#{ver}
git tag v#{version}             	# add version tag
git push --tags
git checkout -          	# back to main branch
git log -1 $cid
git cherry-pick $cid    	# apply the commit to update CHANGES.md
git rm #{project}-#{version}.gem   	# if necessary

END
end


desc "update version number"
task :prepare, [:version] do |t, args|
  version = version_number_required(args, :prepare)
  copyright = COPYRIGHT
  spec = load_gemspec_file("#{PROJECT}.gemspec")
  edit(spec.files) {|s, fpath|
    s = s.gsub(/\$Version\:.*?\$/,   "$Version\: #{version} $")
    s = s.gsub(/\$Version\$/,        version)
    s = s.gsub(/\$Copyright:.*?\$/,  "$Copyright\: #{copyright} $")
    s = s.gsub(/\$Copyright\$/,      copyright)
    if fpath == "MIT-LICENSE"
      if copyright =~ /(\(c\).*)/
        x = $1
        s = s.sub(/^Copyright .*$/, "Copyright #{x}")
      end
    end
    s
  }
end


desc "create gem package"
task "gem:build" do
  sh "gem build #{PROJECT}.gemspec"
end


desc "upload gem to rubygems.org"
task "gem:publish" do
  spec = load_gemspec_file("#{PROJECT}.gemspec")
  version = spec.version.to_s
  gemfile = "#{PROJECT}-#{version}.gem"
  File.exist?(gemfile)  or
    abort "[ERROR] Gem file (#{gemfile}) not found. Run 'rake package' beforehand."
  print "*** Are you sure to upload #{gemfile}? [y/N]: "
  answer = $stdin.gets().strip()
  if answer =~ /\A[yY]/
    #sh "git tag v#{version}"
    sh "gem push #{gemfile}"
  end
end


##
## helpers
##

def edit(*filepaths)
  filepaths.flatten.each do |fpath|
    next if ! File.file?(fpath)
    File.open(fpath, 'r+b:utf-8') do |f|
      s = f.read()
      new_s = yield s, fpath
      if new_s != s
        f.rewind()
        f.truncate(0)
        f.write(new_s)
        puts "[Change] #{fpath}"
      end
    end
  end
end

def load_gemspec_file(gemspec_file)
  require 'rubygems'
  return Gem::Specification::load(gemspec_file)
end

def version_number_required(args, task_name)
  version = args[:version] || ENV['version']
  unless version
    $stderr.puts <<"END"
##
## ERROR: rake #{task_name}: requires 'version=X.X.X' option.
##        For example:
##           $ rake #{task_name} version=1.0.0
##
END
    errmsg = "rake #{task_name}: requires 'version=X.X.X' option."
    raise ArgumentError.new(errmsg)
  end
  return version
end
