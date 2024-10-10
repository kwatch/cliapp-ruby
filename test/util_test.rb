# encoding: utf-8
# frozen_string_literal: true


require_relative './init'


Oktest.scope do


  topic CLIApp::Util do


    topic '#arity_of_proc()' do

      spec "[!get6i] returns min and max arity of proc object." do
        pr1 = proc {|a, b, c=nil, d=nil, x: nil, y: nil| nil }
        ok {CLIApp::Util.arity_of_proc(pr1)} == [2, 4]
        pr2 = proc {|a=nil, b=nil| nil }
        ok {CLIApp::Util.arity_of_proc(pr2)} == [0, 2]
        pr3 = proc { nil }
        ok {CLIApp::Util.arity_of_proc(pr3)} == [0, 0]
      end

      spec "[!ghrxo] returns nil as max arity if proc has variable param." do
        pr1 = proc {|a, b, c=nil, d=nil, *e, x: nil, y: nil| nil }
        ok {CLIApp::Util.arity_of_proc(pr1)} == [2, nil]
        pr2 = proc {|a=nil, b=nil, *c| nil }
        ok {CLIApp::Util.arity_of_proc(pr2)} == [0, nil]
      end

    end


    topic '#argstr_of_proc()' do

      spec "[!gbk7b] generates argument string of proc object." do
        pr1 = proc {|aa, bb, cc=nil, dd=nil, x: nil, y: nil| nil }
        ok {CLIApp::Util.argstr_of_proc(pr1)} == " <aa> <bb> [<cc> [<dd>]]"
      end

      spec "[!b6gzp] required param should be '<param>'." do
        pr1 = proc {|aa, bb| nil }
        ok {CLIApp::Util.argstr_of_proc(pr1)} == " <aa> <bb>"
      end

      spec "[!q1030] optional param should be '[<param>]'." do
        pr1 = proc {|aa=nil, bb=nil| nil }
        ok {CLIApp::Util.argstr_of_proc(pr1)} == " [<aa> [<bb>]]"
      end

      spec "[!osxwq] variable param should be '[<param>...]'." do
        pr1 = proc {|aa, bb=nil, *cc| nil }
        ok {CLIApp::Util.argstr_of_proc(pr1)} == " <aa> [<bb> [<cc>...]]"
      end

    end


    topic '#param2argname()' do

      spec "[!52dzl] converts 'yes_or_no' to 'yes|no'." do
        ok {CLIApp::Util.param2argname("yes_or_no")} == "yes|no"
      end

      spec "[!6qkk6] converts 'file__html' to 'file.html'." do
        ok {CLIApp::Util.param2argname("file__html")} == "file.html"
      end

      spec "[!2kbhe] converts 'aa_bb_cc' to 'aa-bb-cc'." do
        ok {CLIApp::Util.param2argname("aa_bb_cc")} == "aa-bb-cc"
      end

    end


  end


end
