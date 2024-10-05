# -*- coding: utf-8 -*-
# frozen_string_literal: true


require_relative './init'


Oktest.scope do


  topic CLIApp::Application do

    fixture :config do
      CLIApp::Config.new(name: "Sample", desc: "Sample Application",
                         command: "sample", version: "0.1.2")
    end

    fixture :app do |config|
      app = CLIApp::Application.new(config) do |gopts|
        if gopts[:debug]
          $debug_mode = true
          true
        else
          nil
        end
      end
      app.global_options({
        :help    => ["-h", "--help"      , "print help message"],
        :version => ["-V", "--version"   , "print version number"],
      })
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
      app.action("clean", "delete garbage files (& product files too if '-a')", {
        #:all => ["-a", "--all", "delete product files, too"],
      }) do |all: false|
        #require 'fileutils' unless defined?(FileUtils)
        #FileUtils.rm_r(Dir.glob(GARBAGE_FILES))
        #FileUtils.rm_r(Dir.glob(PRODUCT_FILES)) if all
      end
      app
    end

    APP_HELP = <<'END'
Sample (0.1.2) --- Sample Application

Usage:
  $ sample [<options>] <action> [<arguments>...]

Options:
  -h, --help             print help message
  -V, --version          print version number

Actions:
  clean                  delete garbage files (& product files too if '-a')
  hello                  greeting message
END


    topic '#global_options()' do

      spec "[!2kq26] accepts global option schema." do
        |app|
        dict = app.instance_eval { @gopts_schema }
        ok {dict} == {
          :help    => ["-h", "--help"      , "print help message"],
          :version => ["-V", "--version"   , "print version number"],
        }
      end

    end


    topic '#action()' do

      spec "[!i1jjg] converts action name into string." do
        |app|
        action = app.action(:foo, "Foo") do nil end
        ok {action.name} == "foo"
      end

      spec "[!kculn] registers an action." do
        |app|
        action = app.action(:bar, "Bar") do nil end
        ok {app.get_action("bar")}.same?(action)
        ok {app.get_action(:bar) }.same?(action)
      end

      spec "[!82n8q] returns an action object." do
        |app|
        action = app.action(:baz, "Baz") do nil end
        ok {action}.is_a?(CLIApp::Action)
        ok {action.name} == "baz"
      end

    end


    topic '#get_action()' do

      spec "[!hop4z] returns action object if found, nil if else." do
        |app|
        ok {app.get_action("hello")} != nil
        ok {app.get_action("hello")}.is_a?(CLIApp::Action)
        ok {app.get_action(:hello)} != nil
        ok {app.get_action(:hello)}.is_a?(CLIApp::Action)
        ok {app.get_action("helloxx")} == nil
      end

    end


    topic '#each_action()' do

      spec "[!u46wo] returns Enumerator object if block not given." do
        |app|
        ok {app.each_action()}.is_a?(Enumerator)
        ok {app.each_action().collect {|a| a.name }} == ["hello", "clean"]
      end

      spec "[!yorp6] if `sort: true` passed, sort actions by name." do
        |app|
        anames = []
        app.each_action(sort: true) {|a| anames << a.name }
        ok {anames} == ["clean", "hello"]
        #
        anames = []
        app.each_action(sort: false) {|a| anames << a.name }
        ok {anames} == ["hello", "clean"]
      end

      spec "[!ealgm] yields each action object." do
        |app|
        app.each_action() do |a|
          ok {a}.is_a?(CLIApp::Action)
        end
      end

    end


    topic '#main()' do

      spec "[!hopc3] returns 0 if finished successfully." do
        |app|
        ret = nil
        capture_stdout do
          ret = app.main(["hello"])
        end
        ok {ret} == 0
      end

      spec "[!uwcq7] yields block with error object if error raised." do
        |app|
        exc = nil
        app.main(["helloxx"]) do |exc_|
          exc = exc_
        end
        ok {exc}.is_a?(CLIApp::ActionNotFoundError)
        ok {exc.message} == "helloxx: Action not found."
      end

      spec "[!e0t6k] reports error into stderr if block not given." do
        |app|
        serr = capture_stderr do
          app.main(["helloxx"])
        end
        ok {serr} == "[ERROR] helloxx: Action not found.\n"
      end

      spec "[!d0g0w] returns 1 if error raised." do
        |app|
        ret = app.main(["helloxx"]) do end
        ok {ret} == 1
        #
        ret = nil
        capture_stderr do
          ret = app.main(["helloxx"])
        end
        ok {ret} == 1
      end

    end


    topic '#run()' do

      spec "[!qv5fz] parses global options (not parses action options)." do
        |app|
        sout = capture_stdout do
          app.run("hello", "--help")
        end
        ok {sout} =~ /^sample hello --- greeting message$/
      end

      spec "[!kveua] handles global options such as '--help'." do
        |app|
        sout = capture_stdout do
          app.run("--help", "hello")
        end
        ok {sout} =~ /^Sample \(0\.1\.2\) --- Sample Application$/
      end

      spec "[!j029i] prints help message if no action name specified." do
        |app|
        sout = capture_stdout { app.run() }
        ok {sout} =~ /^Sample \(0\.1\.2\) --- Sample Application$/
      end

      spec "[!43u4y] raises error if action name is unknown." do
        |app|
        pr = proc { app.run("helloxx") }
        ok {pr}.raise?(CLIApp::ActionNotFoundError,
                       "helloxx: Action not found.")
      end

      spec "[!lm0ir] parses all action options even after action args." do
        |app|
        sout = capture_stdout do
          app.run("hello", "Alice", "--lang=fr")
        end
        ok {sout} == "Bonjour, Alice!\n"
      end

      spec "[!ehshp] prints action help if action option contains help option." do
        |app|
        sout = capture_stdout do
          app.run("hello", "Alice", "--help")
        end
        ok {sout} =~ /^sample hello --- greeting message$/
      end

      spec "[!0nwwe] invokes an action with action args and options." do
        |app|
        sout = capture_stdout do
          app.run("hello", "--lang=it", "Haruhi")
        end
        ok {sout} == "Chao, Haruhi!\n"
      end

    end


    topic '#handle_global_options()' do

      spec "[!6n0w0] when '-h' or '--help' specified, prints help message and returns true." do
        |app|
        ret = nil
        sout = capture_stdout do
          ret = app.handle_global_options({help: true})
        end
        ok {sout} =~ /^Sample \(0\.1\.2\) --- Sample Application$/
        ok {ret} == true
      end

      spec "[!zii8c] when '-V' or '--version' specified, prints version number and returns true." do
        |app|
        ret = nil
        sout = capture_stdout do
          ret = app.handle_global_options({version: true})
        end
        ok {sout} == "0.1.2\n"
        ok {ret} == true
      end

      spec "[!csw5l] when '-l' or '--list' specified, prints action list and returns true." do
        |app|
        ret = nil
        sout = capture_stdout do
          ret = app.handle_global_options({list: true})
        end
        ok {sout} == <<'END'
clean            : delete garbage files (& product files too if '-a')
hello            : greeting message
END
        ok {ret} == true
      end

      spec "[!5y8ph] if global option handler block specified, call it." do
        |app|
        ret = nil
        sout = capture_stdout do
          ret = app.handle_global_options({list: true})
        end
        ok {sout} == <<'END'
clean            : delete garbage files (& product files too if '-a')
hello            : greeting message
END
        ok {ret} == true
      end

      spec "[!s816x] returns nil if global options are not handled." do
        |app|
        $debug_mode = false
        at_end { $debug_mode = nil }
        ret = nil
        sout = capture_stdout do
          ret = app.handle_global_options({debug: true})
        end
        ok {$debug_mode} == true
        ok {ret} == true
      end

    end


    topic '#application_help_message()' do

      spec "[!p02s2] builds application help message." do
        |app|
        ok {app.application_help_message()} == APP_HELP
      end

      spec "[!41l2g] includes version number if it is specified." do
        |app|
        ok {app.config.version} == "0.1.2"
        ok {app.application_help_message()} =~ /^Sample \(0\.1\.2\) ---/
        app2 = CLIApp.new("Sample", "Sample App", command: "sample", version: nil)
        ok {app2.application_help_message()} =~ /^Sample ---/
      end

      spec "[!2eycw] includes 'Options:' section if any global options exist." do
        |app|
        ok {app.application_help_message()} =~ /^Options:$/
        ok {app.application_help_message()} =~ /^  \$ sample \[<options>\] <action> \[<arguments>\.\.\.\]$/
        app2 = CLIApp.new("Sample", "Sample App", command: "sample", version: nil)
        app2.action("hello", "Hello") do end
        ok {app2.application_help_message()} !~ /^Options:$/
        ok {app2.application_help_message()} =~ /^  \$ sample <action> \[<arguments>\.\.\.\]$/
      end

      spec "[!x3dim] includes 'Actions:' section if any actions defined." do
        |app|
        ok {app.application_help_message()} =~ /^Actions:$/
        ok {app.application_help_message()} =~ /^  \$ sample \[<options>\] <action> \[<arguments>\.\.\.\]$/
        app2 = CLIApp.new("Sample", "Sample App", command: "sample", version: nil)
        app2.global_options({:version=>["-V", "version"]})
        ok {app2.application_help_message()} !~ /^Actions:$/
        ok {app2.application_help_message()} =~ /^  \$ sample \[<options>\]$/
      end

      spec "[!vxcin] help message will be affcted by config." do
        |app|
        app.config.help_indent = "  | "
        app.config.help_option_width = 14
        app.config.help_action_width = 6
        ok {app.application_help_message()} == <<'END'
Sample (0.1.2) --- Sample Application

Usage:
  | $ sample [<options>] <action> [<arguments>...]

Options:
  | -h, --help     print help message
  | -V, --version  print version number

Actions:
  | clean  delete garbage files (& product files too if '-a')
  | hello  greeting message
END
      end

    end


    topic '#action_help_message()' do

      ACTION_HELP = <<'END'
sample hello --- greeting message

Usage:
  $ sample hello [<options>] [<name>]

Options:
  -l, --lang=<en|fr|it>  language
END

      spec "[!ny72g] build action help message." do
        |app|
        action = app.get_action(:hello)
        ok {app.action_help_message(action)} == ACTION_HELP
      end

      spec "[!pr2vy] includes 'Options:' section if any options exist." do
        |app|
        hello = app.get_action(:hello)
        ok {app.action_help_message(hello)} =~ /^Options:$/
        ok {app.action_help_message(hello)} =~ /^  \$ sample hello \[<options>\] \[<name>\]$/
        clean = app.get_action(:clean)
        ok {app.action_help_message(clean)} !~ /^Options:$/
        ok {app.action_help_message(clean)} =~ /^  \$ sample clean$/
      end

      spec "[!1xggx] help message will be affcted by config." do
        |app|
        app.config.help_indent = " | "
        app.config.help_option_width = 25
        hello = app.get_action(:hello)
        ok {app.action_help_message(hello)} == <<'END'
sample hello --- greeting message

Usage:
 | $ sample hello [<options>] [<name>]

Options:
 | -l, --lang=<en|fr|it>     language
END
      end

    end


    topic '#parse_global_options()' do

      spec "[!o83ty] parses global options and returns it." do
        |app|
        args = ["-h", "--version", "hello", "--help", "--lang=it"]
        opts = app.parse_global_options(args)
        ok {opts} == {help: true, version: true}
        ok {args} == ["hello", "--help", "--lang=it"]
      end

    end


    topic '#parse_action_options()' do

      spec "[!5m767] parses action options and returns it." do
        |app|
        action = app.get_action(:hello)
        args = ["Alice", "-h", "--lang=it", "Carol"]
        opts = app.parse_action_options(action, args)
        ok {opts} == {help: true, lang: "it"}
        ok {args} == ["Alice", "Carol"]
      end

      spec "[!k2cto] adds '-h, --help' option automatically." do
        |app|
        action = app.get_action(:clean)
        ok {action.option_schema.keys()} == []
        args = ["--help"]
        opts = app.parse_action_options(action, args)
        ok {opts} == {help: true}
      end

    end


    topic '#prepare_parser()' do

      spec "[!vcgq0] adds all option schema into parser." do
        |app|
        parser = app.instance_eval do
          parser = new_parser()
          prepare_parser(parser, {:quiet=>["-q", "Quiet"]})
          parser
        end
        ok {parser.summarize()[0]} =~ /^ +-q +Quiet$/
      end

      spec "[!lcpvw] returns hash object which stores options." do
        |app|
        parser = opts = nil
        app.instance_eval do
          parser = new_parser()
          opts = prepare_parser(parser, {:quiet=>["-q", "Quiet"]})
        end
        ok {opts} == {}
        parser.parse(["-q"])
        ok {opts} == {quiet: true}
      end

    end


    topic '#new_parser()' do

      spec "[!lnbpm] creates new parser object." do
        |app|
        parser = app.instance_eval { new_parser() }
        ok {parser}.is_a?(OptionParser)
      end

    end


    topic '#option_help_message()' do

      spec "[!lfnlq] builds help message of options." do
        |app|
        schema = {
          :verbose => ["-v", "--verbose", "Verbse mode"],
          :quiet   => ["-q", "Quiet mode"],
        }
        str = app.instance_eval {
          option_help_message(schema, width: 20, indent: "   ")
        }
        ok {str} == <<END
   -v, --verbose        Verbse mode
   -q                   Quiet mode
END
      end

    end


    topic '#list_actions()' do

      spec "[!g99qx] returns list of action names and descriptions as a string." do
        |app|
        str = app.instance_eval { list_actions() }
        ok {str} == <<'END'
clean            : delete garbage files (& product files too if '-a')
hello            : greeting message
END
      end

      spec "[!rl5hs] sorts actions by name." do
        |app|
        str = app.instance_eval { list_actions() }
        names = str.each_line.grep(/^(\w+)/) { $1 }
        ok {names} == ["clean", "hello"]
      end

      spec "[!rlak5] print only the first line of multiline description." do
        |app|
        app.get_action(:clean).instance_variable_set(:@desc, "AA\nBB\nCC")
        str = app.instance_eval { list_actions() }
        ok {str} == <<END
clean            : AA
hello            : greeting message
END
      end

      spec "[!1xggx] output will be affcted by config." do
        |app|
        app.config.actionlist_width = 7
        str = app.instance_eval { list_actions() }
        ok {str} == <<'END'
clean   : delete garbage files (& product files too if '-a')
hello   : greeting message
END
        #
        app.config.actionlist_format = " - %-10s # %s"
        str = app.instance_eval { list_actions() }
        ok {str} == <<'END'
 - clean      # delete garbage files (& product files too if '-a')
 - hello      # greeting message
END
      end

    end


    topic '#do_when_action_not_specified()' do

      spec "[!w5lq9] prints application help message." do
        |app|
        sout = capture_stdout() do
          app.instance_eval do
            do_when_action_not_specified({})
          end
        end
        ok {sout} == APP_HELP
      end

      spec "[!txqnr] returns true which means 'done'." do
        |app|
        ret = nil
        capture_stdout() do
          app.instance_eval do
            ret = do_when_action_not_specified({})
          end
        end
        ok {ret} == true
      end

    end


  end


end
