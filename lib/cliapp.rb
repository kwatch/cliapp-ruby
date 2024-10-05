# -*- coding: utf-8 -*-
# frozen_string_literal: true

##
## Command-Line Application Framework
##
## $Version: 0.0.0 $
## $Copyright: copyright (c)2024 kwatch@gmail.com $
## $License: MIT License $
##

require 'optparse'


module CLIApp


  class ActionError < StandardError; end
  class ActionNotFoundError    < ActionError; end
  class ActionTooFewArgsError  < ActionError; end
  class ActionTooManyArgsError < ActionError; end


  class Action

    def initialize(name, desc=nil, option_schema={}, &block)
      @name = name
      @desc = desc
      @option_schema = option_schema
      @block = block
    end

    attr_reader :name, :desc, :option_schema, :block

    def call(*args, **opts)
      #; [!pc2hw] raises error when fewer arguments.
      n_min, n_max = Util.arity_of_proc(@block)
      args.length >= n_min  or
        raise ActionTooFewArgsError, "Too few arguments."
      #; [!6vdhh] raises error when too many arguments.
      n_max == nil || args.length <= n_max  or
        raise ActionTooManyArgsError, "Too many arguments."
      #; [!7n4hs] invokes action block with args and kwargs.
      if opts.empty?                 # for Ruby < 2.7
        @block.call(*args)           # for Ruby < 2.7
      else
        @block.call(*args, **opts)
      end
    end

  end


  class Config

    def initialize(name: nil, desc: nil, version: nil, command: nil,
                   help_indent: nil, help_option_width: nil, help_action_width: nil,
                   actionlist_width: nil, actionlist_format: nil)
      command ||= File.basename($0)
      @name    = name || command     # ex: "FooBar"
      @desc    = desc                # ex: "Foo Bar application"
      @command = command             # ex: "foobar"
      @version = version             # ex: "1.0.0"
      @help_indent        = help_indent        || "  "
      @help_option_width  = help_option_width  || 22
      @help_action_width  = help_action_width  || 22
      @actionlist_width   = actionlist_width   || 16
      @actionlist_format  = actionlist_format  || nil # ex: "%-16s : %s"
    end

    attr_accessor :name, :desc, :command, :version
    attr_accessor :help_indent, :help_option_width, :help_action_width
    attr_accessor :actionlist_width, :actionlist_format

  end


  def self.new(name, desc, version: nil, command: nil, **kws, &gopts_handler)
    #; [!gpvqe] creates new Config object internally.
    config = Config.new(name: name, desc: desc, version: version, command: command, **kws)
    #; [!qyunk] creates new Application object with config object created.
    return Application.new(config, &gopts_handler)
  end


  class Application

    def initialize(config, &gopts_handler)
      @config        = config
      @gopts_handler = gopts_handler
      @gopts_schema  = {}  # ex: {:help => ["-h", "--hel", "help message"}
      @actions       = {}  # ex: {"clean" => Action.new(:clean, "delete files", {:all=>["-a", "all"]})}
    end

    attr_reader :config

    def global_options(option_schema={})
      #; [!2kq26] accepts global option schema.
      @gopts_schema = option_schema
      nil
    end

    def action(name, desc, schema_dict={}, &block)
      #; [!i1jjg] converts action name into string.
      name = name.to_s
      #; [!kculn] registers an action.
      action = Action.new(name, desc, schema_dict, &block)
      @actions[name] = action
      #; [!82n8q] returns an action object.
      return action
    end

    def get_action(name)
      #; [!hop4z] returns action object if found, nil if else.
      return @actions[name.to_s]
    end

    def each_action(sort: false, &b)
      #; [!u46wo] returns Enumerator object if block not given.
      return to_enum(:each_action, sort: sort) unless block_given?()
      #; [!yorp6] if `sort: true` passed, sort actions by name.
      names = @actions.keys
      names = names.sort if sort
      #; [!ealgm] yields each action object.
      names.each do |name|
        yield @actions[name]
      end
      nil
    end

    def main(argv=ARGV, &error_handler)
      #; [!hopc3] returns 0 if finished successfully.
      run(*argv)
      return 0
    rescue OptionParser::ParseError, CLIApp::ActionError => exc
      #; [!uwcq7] yields block with error object if error raised.
      if block_given?()
        yield exc
      #; [!e0t6k] reports error into stderr if block not given.
      else
        $stderr.puts "[ERROR] #{exc.message}"
      end
      #; [!d0g0w] returns 1 if error raised.
      return 1
    end

    def run(*args)
      #; [!qv5fz] parses global options (not parses action options).
      global_opts = parse_global_options(args)
      #; [!kveua] handles global options such as '--help'.
      done = handle_global_options(global_opts)
      return if done
      #; [!j029i] prints help message if no action name specified.
      if args.empty?
        done = do_when_action_not_specified(global_opts)
        return if done
      end
      #; [!43u4y] raises error if action name is unknown.
      action_name = args.shift()
      action = get_action(action_name)  or
        raise ActionNotFoundError, "#{action_name}: Action not found."
      #; [!lm0ir] parses all action options even after action args.
      action_opts = parse_action_options(action, args)
      #; [!ehshp] prints action help if action option contains help option.
      if action_opts[:help]
        print action_help_message(action)
        return
      end
      #; [!0nwwe] invokes an action with action args and options.
      action.call(*args, **action_opts)
    end

    def handle_global_options(global_opts)
      #; [!6n0w0] when '-h' or '--help' specified, prints help message and returns true.
      if global_opts[:help]
        print application_help_message()
        return true
      end
      #; [!zii8c] when '-V' or '--version' specified, prints version number and returns true.
      if global_opts[:version]
        puts @config.version
        return true
      end
      #; [!csw5l] when '-l' or '--list' specified, prints action list and returns true.
      if global_opts[:list]
        print list_actions()
        return true
      end
      #; [!5y8ph] if global option handler block specified, call it.
      if (handler = @gopts_handler)
        return !! handler.call(global_opts)
      end
      #; [!s816x] returns nil if global options are not handled.
      return nil
    end

    def application_help_message(width: nil, indent: nil)
      #; [!p02s2] builds application help message.
      #; [!41l2g] includes version number if it is specified.
      #; [!2eycw] includes 'Options:' section if any global options exist.
      #; [!x3dim] includes 'Actions:' section if any actions defined.
      #; [!vxcin] help message will be affcted by config.
      c = @config
      indent ||= c.help_indent
      options_str = option_help_message(@gopts_schema, width: width, indent: indent)
      format = "#{indent}%-#{width || c.help_action_width}s %s\n"
      actions_str = each_action(sort: true).collect {|action|
        format % [action.name, action.desc]
      }.join()
      optstr = options_str.empty? ? "" : " [<options>]"
      actstr = actions_str.empty? ? "" : " <action> [<arguments>...]"
      ver = c.version ? " (#{c.version})" : nil
      sb = []
      sb << <<"END"
#{c.name}#{ver} --- #{c.desc}

Usage:
#{indent}$ #{c.command}#{optstr}#{actstr}
END
      sb << (options_str.empty? ? "" : <<"END")

Options:
#{options_str.chomp()}
END
      sb << (actions_str.empty? ? "" : <<"END")

Actions:
#{actions_str.chomp()}
END
      return sb.join()
    end

    def action_help_message(action, width: nil, indent: nil)
      #; [!ny72g] build action help message.
      #; [!pr2vy] includes 'Options:' section if any options exist.
      #; [!1xggx] help message will be affcted by config.
      options_str = option_help_message(action.option_schema, width: width, indent: indent)
      optstr = options_str.empty? ? "" : " [<options>]"
      argstr = Util.argstr_of_proc(action.block)
      c = @config
      sb = []
      sb << <<"END"
#{c.command} #{action.name} --- #{action.desc}

Usage:
#{c.help_indent}$ #{c.command} #{action.name}#{optstr}#{argstr}
END
      sb << (options_str.empty? ? "" : <<"END")

Options:
#{options_str.chomp()}
END
      return sb.join()
    end

    def parse_global_options(args)
      #; [!o83ty] parses global options and returns it.
      parser = new_parser()
      global_opts = prepare_parser(parser, @gopts_schema)
      parser.order!(args)    # not parse options after arguments
      return global_opts
    end

    def parse_action_options(action, args)
      #; [!5m767] parses action options and returns it.
      parser = new_parser()
      action_opts = prepare_parser(parser, action.option_schema)
      #; [!k2cto] adds '-h, --help' option automatically.
      parser.on("-h", "--help", "print help message") {|v| action_opts[:help] = v }
      parser.permute!(args)  # parse all options even after arguments
      return action_opts
    end

    protected

    def prepare_parser(parser, schema_dict, opts={})
      #; [!vcgq0] adds all option schema into parser.
      ## ex: schema_dict == {:help => ["-h", "--help", "help msg"]}
      schema_dict.each do |key, arr|
        parser.on(*arr) {|v| opts[key] = v }
      end
      #; [!lcpvw] returns hash object which stores options.
      return opts
    end

    def new_parser(*args)
      #; [!lnbpm] creates new parser object.
      parser = OptionParser.new(*args)
      #parser.require_exact = true
      return parser
    end

    def option_help_message(option_schema, width: nil, indent: nil)
      #; [!lfnlq] builds help message of options.
      c = @config
      width  ||= c.help_option_width
      indent ||= c.help_indent
      parser = new_parser(nil, width, indent)
      prepare_parser(parser, option_schema)
      return parser.summarize().join()
    end

    def list_actions()
      #; [!1xggx] output will be affcted by config.
      c = @config
      format = c.actionlist_format || "%-#{c.actionlist_width}s : %s"
      format += "\n" unless format.end_with?("\n")
      #; [!g99qx] returns list of action names and descriptions as a string.
      #; [!rl5hs] sorts actions by name.
      return each_action(sort: true).collect {|action|
        #; [!rlak5] print only the first line of multiline description.
        desc = (action.desc || "").each_line.take(1).first.chomp()
        format % [action.name, desc]
      }.join()
    end

    def do_when_action_not_specified(global_opts)
      #; [!w5lq9] prints application help message.
      print application_help_message()
      #; [!txqnr] returns true which means 'done'.
      return true
    end

  end


  module Util
    module_function

    def arity_of_proc(proc_)
      #; [!get6i] returns min and max arity of proc object.
      #; [!ghrxo] returns nil as max arity if proc has variable param.
      n_max = 0
      n_min = proc_.arity
      n_min = - (n_min + 1) if n_min < 0
      has_rest = false
      proc_.parameters.each do |ptype, _|
        case ptype
        when :req, :opt ; n_max += 1
        when :rest      ; has_rest = true
        end
      end
      return n_min, (has_rest ? nil : n_max)
    end

    def argstr_of_proc(proc_)
      #; [!gbk7b] generates argument string of proc object.
      n = proc_.arity
      n = - (n + 1) if n < 0
      sb = []; cnt = 0
      proc_.parameters.each do |(ptype, pname)|
        aname = param2argname(pname)
        case ptype
        when :req, :opt
          #; [!b6gzp] required param should be '<param>'.
          #; [!q1030] optional param should be '[<param>]'.
          n -= 1
          if n >= 0 ; sb <<  " <#{aname}>"
          else      ; sb << " [<#{aname}>" ; cnt += 1
          end
        when :rest
          #; [!osxwq] variable param should be '[<param>...]'.
          sb << " [<#{aname}>...]"
        end
      end
      sb << ("]" * cnt)
      return sb.join()
    end

    def param2argname(name)
      #; [!52dzl] converts 'yes_or_no' to 'yes|no'.
      #; [!6qkk6] converts 'file__html' to 'file.html'.
      #; [!2kbhe] converts 'aa_bb_cc' to 'aa-bb-cc'.
      name = name.to_s
      name = name.gsub('_or_', '|')  # ex: 'yes_or_no' -> 'yes|no'
      name = name.gsub('__', '.')    # ex: 'file__html' -> 'file.html'
      name = name.gsub('_', '-')     # ex: 'src_dir' -> 'src-dir'
      return name
    end

  end


  def self.skeleton()
    #; [!zls9g] returns example code.
    return File.read(__FILE__).split(/^__END__\n/, 2)[1]
  end


end


__END__
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
