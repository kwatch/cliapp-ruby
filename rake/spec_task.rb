# encoding: utf-8
# frozen_string_literal: true


##
## specs:lib
##
desc "list specs in 'lib/**/*.rb'"
task "specs:lib" do
  dirs = ["lib"]
  dirs.each do |dir|
    Dir.glob(dir + "/**/*.rb").each do |filepath|
      list_specs_in_ruby_file(filepath)
    end
  end
end

def list_specs_in_ruby_file(filepath)
  rexp = /^\s*#; +(.*)/               # ex: '#; should return true.'
  #rexp = /^\s*#; +(\[![^\]]+\].*)/   # ex: '#; [!jxl4x] should return true.'
  File.open(filepath) do |f|
    f.grep(rexp) do
      spec = $1
      puts spec
    end
  end
end


##
## specs:test
##
desc "list specs in 'test/**/*_test.rb'"
task "specs:test" do
  dirs = ["test"]
  dirs.each do |dir|
    Dir.glob(dir + "/**/*_test.rb").each do |filepath|
      list_specs_in_test_script(filepath)
    end
  end
end

def list_specs_in_test_script(filepath)
  ## ex: 'it "should return true."'
  rexp = /^\s*(?:spec|it|context|case_when|case_else) (['"])(.*)\1/
  ## ex: 'it "[!jxl4x] should return true."'
  #rexp = /^\s*(?:spec|it|context|case_when|case_else) (['"])(\[![^\]]+\].*)\1/
  File.open(filepath) do |f|
    f.grep(rexp) do |*a|
      q = $1; spec = $2
      if q == '"'
        puts spec.gsub(/\\([\\"])/) { $1 }
      else
        puts spec.gsub(/\\([\\'])/) { $1 }
      end
    end
  end
end


##
## specs:diff
##
desc "diff specs between 'lib/' and 'test/'"
task "specs:diff" do
  sh "bash -c 'diff -u <(rake specs:lib | sort) <(rake specs:test | sort)'"
end
