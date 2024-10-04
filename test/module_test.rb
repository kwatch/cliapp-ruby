# -*- coding: utf-8 -*-
# frozen_string_literal: true


require_relative './init'


Oktest.scope do


  topic CLIApp do


    topic '.new()' do

      fixture :app do
        CLIApp.new("Sample", "Sample App", command: "sample", version: "1.2.3")
      end

      spec "[!gpvqe] creates new Config object internally." do
        |app|
        ok {app.config.name}    == "Sample"
        ok {app.config.desc}    == "Sample App"
        ok {app.config.command} == "sample"
        ok {app.config.version} == "1.2.3"
      end

      spec "[!qyunk] creates new Application object with config object created." do
        |app|
        ok {app}.is_a?(CLIApp::Application)
        ok {app.config}.is_a?(CLIApp::Config)
      end

    end


    topic '.skeleton()' do

      GLOBAL_HELP = <<'END'
Sample (1.0.0) --- Sample Application

Usage:
  $ tmp.sample [<options>] <action> [<arguments>...]

Options:
  -h, --help             print help message
      --version          print version number
  -l, --list             list action names

Actions:
  clean                  delete garbage files (& product files too if '-a')
  hello                  greeting message
END

      HELLO_HELP = <<'END'
tmp.sample hello --- greeting message

Usage:
  $ tmp.sample hello [<options>] [<name>]

Options:
  -l, --lang=<en|fr|it>  language
END

      spec "[!zls9g] returns example code." do
        str = CLIApp.skeleton()
        ok {str}.is_a?(String)
        filename = "tmp.sample"
        dummy_file(filename, str)
        #
        sout, serr = capture_command "ruby #{filename} --help"
        ok {serr} == ""
        ok {sout} == GLOBAL_HELP
        #
        sout, serr = capture_command "ruby #{filename} hello --help"
        ok {serr} == ""
        ok {sout} == HELLO_HELP
        #
        sout, serr = capture_command "ruby #{filename} hello"
        ok {serr} == ""
        ok {sout} == "Hello, world!\n"
        sout, serr = capture_command "ruby #{filename} hello Alice --lang=fr"
        ok {serr} == ""
        ok {sout} == "Bonjour, Alice!\n"
      end

    end

  end


end
