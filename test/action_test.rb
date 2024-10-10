# encoding: utf-8
# frozen_string_literal: true


require_relative './init'


Oktest.scope do


  topic CLIApp::Action do

    fixture :action do
      CLIApp::Action.new("hello", nil) do |aa, bb, cc=nil|
        [aa, bb, cc]
      end
    end


    topic '#call()' do

      spec "[!pc2hw] raises error when fewer arguments." do
        |action|
        pr = proc { action.call(10) }
        ok {pr}.raise?(CLIApp::ActionTooFewArgsError,
                       "Too few arguments.")
      end

      spec "[!6vdhh] raises error when too many arguments." do
        |action|
        pr = proc { action.call(10, 20, 30, 40) }
        ok {pr}.raise?(CLIApp::ActionTooManyArgsError,
                       "Too many arguments.")
      end

      spec "[!7n4hs] invokes action block with args and kwargs." do
        |action|
        ret1 = nil
        pr1 = proc { ret1 = action.call(10, 20) }
        ok {pr1}.raise_nothing?
        ok {ret1} == [10, 20, nil]
        ret2 = nil
        pr2 = proc { ret2 = action.call(10, 20, 30) }
        ok {pr2}.raise_nothing?
        ok {ret2} == [10, 20, 30]
      end

    end


  end


end
