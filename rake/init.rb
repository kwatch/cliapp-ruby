# coding: euc-jp
# frozen_string_literal: true


if defined?(Rake)

  ## set prompt for FileUtils commands
  prompt = "\e[90m[rake]\e[0m$ "     if $stdout.tty?
  prompt = "[rake]$ "            unless $stdout.tty?
  @fileutils_label = prompt
  Rake.instance_variable_set(:@fileutils_label, prompt)

  ## set prompt for 'sh()' command
  Rake::FileUtilsExt.module_eval do
    def rake_output_message(message)
      fu_output_message(message)
    end
  end

  ## interoperability with Benry-MicroRake
  Rake::DSL.module_eval do
    alias __rake_desc desc
    def desc(description, *args, **kwargs)
      __rake_desc(description)  # ignore extra args and kwargs
    end
    def run_task(name)
      Rake::Task[name].invoke()
    end
    def task_defined?(name)
      Rake::Task.task_defined?(name)
    end
  end

end
