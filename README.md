CLIApp
======

($Version: 0.0.0 $)

CLIApp is a small framework for command-line application.
If you need to create a CLI app such as Git or Docker, CLIApp is one of the solutions.

* GitHub: https://github.com/kwatch/cliapp-ruby/


Quick Start
-----------

```console
$ gem install cliapp
$ ruby -r cliapp -e 'puts CLIApp.skeleton' > sample
$ chmod a+x sample
$ ./sample --help | less
$ ./sample hello
Hello, world!
$ ./sample hello Alice --lang=fr
Bonjour, Alice!
```


Sample Code
-----------

File: sample

```ruby
#!/usr/bin/env ruby
# coding: utf-8
# frozen_string_literal: true

require 'cliapp'

## create an application object
app = CLIApp.new("Sample", "Sample Application",
                 #command: "sample",    # default: File.basename($0)
                 version: "1.0.0")
app.global_options({
  :help    => ["-h", "--help"      , "print help message"],
  :version => [      "--version"   , "print version number"],
  :list    => ["-l", "--list"      , "list action names"],
})

## 'hello' action
app.action("hello", "greeting message", {
  :lang => ["-l", "--lang=<en|fr|it>", "language", ["en", "it", "fr"]],
}) do |name="world", lang: "en"|
  case lang
  when "en"  ; puts "Hello, #{name}!"
  when "fr"  ; puts "Bonjour, #{name}!"
  when "it"  ; puts "Chao, #{name}!"
  else  raise "** internal error: lang=#{lang.inspect}"
  end
end

## 'clean' action
app.action("clean", "delete garbage files (& product files too if '-a')", {
  :all => ["-a", "--all", "delete product files, too"],
}) do |all: false|
  require 'fileutils' unless defined?(FileUtils)
  FileUtils.rm_r(Dir.glob(GARBAGE_FILES), verbose: true)
  FileUtils.rm_r(Dir.glob(PRODUCT_FILES), verbose: true) if all
end
GARBAGE_FILES = []
PRODUCT_FILES = []

## main
status_code = app.main(ARGV)
exit status_code
## or
#begin
#  app.run(*ARGV)
#  exit 0
#rescue OptionParser::ParseError, CLIApp::ActionError => exc
#  $stderr.puts "[ERROR] #{exc.message}"
#  exit 1
#end
```

Output example:

```console
$ chmod a+x sample

$ ./sample -l
clean            : delete garbage files (& product files too if '-a')
hello            : greeting message

$ ./sample hello --help
sample hello --- greeting message

Usage:
  $ sample hello [<options>] [<name>]

Options:
  -l, --lang=<en|fr|it>  language

$ ./sample hello
Hello, world!

$ ./sample hello Alice --lang=fr
Bonjour, Alice!

$ ./sample hello Alice Bob
[ERROR] Too many arguments.

$ ./sample hello --lang
[ERROR] missing argument: --lang

$ ./sample hello --lang=ja
[ERROR] invalid argument: --lang=ja

$ ./sample hello --language=en
[ERROR] invalid option: --language=en
```


License and Copyright
---------------------

$License: MIT License $

$Copyright: copyright(c) 2024 kwatch@gmail.com $
