#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe Runner do
    let(:config) do
      c = mock
      c.stubs(:loadconfig)
      c.stubs(:configured).returns(true)
      c.stubs(:mode=)
      c
    end

    let(:stats) { mock }

    let(:security) do
      s = mock
      s.stubs(:initiated_by=)
      s
    end

    let(:connector) do
      c = mock
      c.stubs(:connect)
      c
    end

    let(:agents) { mock }

    before :each do
      Config.stubs(:instance).returns(config)
      PluginManager.stubs(:[]).with('global_stats').returns(stats)
      PluginManager.stubs(:[]).with('security_plugin').returns(security)
      PluginManager.stubs(:[]).with('connector_plugin').returns(connector)
      Agents.stubs(:new).returns(agents)
    end

    describe 'initialize' do
      it 'should set up the signal handlers when not on windows' do
        Util.stubs(:windows).returns(false)
        Signal.expects(:trap).with('USR1').yields
        Signal.expects(:trap).with('USR2').yields
        agents.expects(:loadagents)
        Log.expects(:info).twice
        Log.expects(:cycle_level)
        Runner.new(nil)
      end

      it 'should not set up the signal handlers when on windows' do
        Util.stubs(:windows?).returns(true)
        Signal.expects(:trap).with('USR1').never
        Signal.expects(:trap).with('USR2').never
        Util.expects(:setup_windows_sleeper)
        Runner.new(nil)
      end

      it 'should log a message when it cannot initialize the runner' do
        Config.stubs(:instance).raises('failure')
        Log.expects(:error).times(3)
        expect {
          Runner.new(nil)
        }.to raise_error 'failure'
      end
    end

    describe '#run' do
      let(:runner) do
        Runner.new(nil)
      end

      before :each do
        Data.stubs(:load_data_sources)
        Util.stubs(:make_subscriptions)
        Util.stubs(:subscribe)
        config.stubs(:direct_addressing).returns(false)
      end

      it 'should recieve a message' do
        connector.expects(:receive)
        runner.stop
        runner.run
      end

      it 'should handle MessageNotReceived' do
        connector.stubs(:receive).raises(MessageNotReceived.new(15))
        Log.expects(:warn)
        runner.expects(:sleep).with(15)
        runner.stop
        runner.run
      end
    end
  end
end
