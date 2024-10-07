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


desc "run release task interactively"
task "release:wizard", [:version] do |t, args|
  version = args[:version]
  _release_wizard(PROJECT, version)
  ## or, if you prefer shell script...
  #shell_script = File.dirname(__FILE__) + "/release-wizard.sh"
  #system "sh #{shell_script} 'rake release:howto[#{version}]'"
end

def _release_wizard(project, version)
  howto = _release_howto(project, version)
  vars = {}
  howto.each_line do |line|
    next if line =~ /^#/ || line =~ /^$/
    #
    if line =~ /(.*)\t(#.*)/
      command = $1.strip
      comment = $1
    else
      command = line.strip
      comment = nil
    end
    #
    puts "** Next: #{line.strip}"
    print "** Run? [Y/n/q]: "
    answer = $stdin.readline().strip()
    if answer =~ /^n/i
      puts ""
      next
    end
    if answer =~ /^q/i
      puts "** Quit."
      break
    end
    #
    puts "$ #{command}"
    case command
    when /^(\w+)=\$\((.*)\)$/      # ex: 'cid="$(git log -1 | awk 'NR==1{print}')"'
      var = $1
      output = `#{$2}`
      vars[var] = output.chomp
      ok = ($?.exitstatus == 0)
    when /\$(\w+)$/                # ex: 'git cherry-pick $cid'
      var = $1
      if vars.key?(var)
        command = command.sub(/\$\w+$/, vars[var])
      end
      ok = system command
    else
      ok = system command
    end
    #
    if ! ok
      print "# Command failed: Continue? [y/n]: "
      cont_p = nil
      while true
        answer = $stdin.readline().strip()
        case answer
        when /y/i ; cont_p = true  ; break
        when /n/i ; cont_p = false ; break
        else      ; print "** Please answer 'y' or 'n'. Continue? [y/n]: "
        end
      end
      if cont_p == false
        puts "** Quit."
        break
      end
    end
    puts ""
  end
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
