# -*- coding: utf-8 -*-


desc "update version number"
task :prepare, [:version] do |t, args|
  version = version_number_required(args, :prepare)
  edit(spec.files) {|s|
    s.gsub(/\$Version\:.*?\$/,   "$Version\: #{version} $") \
     .gsub(/\$Version\$/,        version)
  }
end


desc "create gem package"
task :package do
  sh "gem build #{SPECFILE}"
end


desc "upload gem to rubygems.org"
task :release, [:version] => :package do |t, args|
  version = version_number_required(args, :release)
  spec = load_gemspec_file(SPECFILE)
  version == spec.version  or
    raise "Version in gemspec file (#{spec.version}) is different from #{version}"
  gemfile = "#{PROJECT}-#{version}.gem"
  print "*** Are you sure to upload #{gemfile}? [y/N]: "
  answer = gets().strip()
  if answer =~ /\A[yY]/
    sh "git tag v#{version}"
    #sh "git tag rel-#{version}"
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
      new_s = yield s
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

def version_number_required(arg, task_name)
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
