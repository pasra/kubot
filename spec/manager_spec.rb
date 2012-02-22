require_relative './spec_helper'
require 'kubot/manager'
require 'tmpdir'
require_relative Kubot::MOCK_PATH+"/foo"
require_relative Kubot::MOCK_PATH+"/bar"
require_relative Kubot::MOCK_PATH+"/multi"
require_relative Kubot::MOCK_PATH+"/exist"

describe Kubot::Manager do
  before :each do
    Kernel.stub(:load)
  end

  subject { Kubot::Manager.new(Kubot::MOCK_LOAD_PATH) }

  it 'has accessor for load path' do
    subject.load_path.should == Kubot::MOCK_LOAD_PATH
  end

  describe '.new' do
    it 'accepts Array as load_path, bot list' do
      expect { Kubot::Manager.new(Kubot::MOCK_LOAD_PATH) }.to_not raise_error
    end
  end

  describe '#locate' do
    it 'returns bot file name found in load_path' do
      subject.locate(:foo).should == "#{Kubot::MOCK_PATH}/foo.rb"
      subject.locate(:bar).should == "#{Kubot::MOCK_PATH}/bar.rb"
      subject.locate(:shouldnt_exist).should be_nil
    end
  end

  describe '#load' do
    it 'accepts bot name, config, option' do
      expect { subject.load(:foo) }.to_not raise_error
      expect { subject.load(:foo, {the: :config}) }.to_not raise_error
      expect { subject.load(:foo, {the: :config}, {db: nil}) }.to_not raise_error
    end

    it 'finds bot using #locate start it' do
      config= {the: :config}
      option= {db: nil}
      dummy = "this is a dummy"
      subject.should_receive(:locate).with(:foo).and_return(dummy)
      FooBot.should_receive(:new).with(config, option).and_return(nil)
      Kubot::Bot.stub(:bots_diff).and_yield.and_return([FooBot])
      Kernel.should_receive(:load).with(dummy)
      File.stub(:mtime){Time.now}
      subject.load(:foo, config, option)
    end

    it 'detects bot using bots_diff' do
      Kubot::Bot.should_receive(:bots_diff).and_return([FooBot])
      bot = FooBot.new
      FooBot.should_receive(:new).and_return(bot)
      subject.load(:foo)
    end

    it 'reloads bot using #reload if it has already loaded' do
      subject.should_receive(:reload).with(:foo, {the: :config}, {}).once
      subject.load(:foo, {the: :config})
      subject.load(:foo, {the: :config})
    end

    it 'raises error unless bot file is found' do
      subject.stub(:locate){nil}
      expect { subject.load(:this_is_not_exist) }.to raise_error(Kubot::Manager::BotNotFound)
    end

    it "doesn't share Bot instances" do
      another = Kubot::Manager.new(Kubot::MOCK_LOAD_PATH)
      bot = FooBot.new
      Kubot::Bot.stub(:bots_diff) { [FooBot] }
      FooBot.should_receive(:new).and_return { bot }
      subject.load(:foo)
      FooBot.should_receive(:new).and_return { bot }
      another.load(:foo)
    end

    it 'starts bots both already exist and added' do
      bot_a = [EaBot.new, EaBot.new]
      bot_b = EbBot.new

      Kubot::Bot.stub(:bots_diff) { [EaBot] }
      EaBot.should_receive(:new).and_return(bot_a.shift)
      subject.load(:exist)

      Kubot::Bot.stub(:bots_diff) { [EbBot] }
      EaBot.should_receive(:new).and_return(bot_a.shift)
      EbBot.should_receive(:new).and_return(bot_b)
      subject.load(:exist)
    end

    context 'with multiple bots in single file' do
      it 'loads all bots in a file and start all of them' do
        Kubot::Bot.stub(:bots_diff) { [MaBot, MbBot] }

        [MaBot, MbBot].each do |klass|
          bot = klass.new
          klass.should_receive(:new).and_return(bot)
        end

        subject.load(:multi)
      end
    end
  end

  describe '#unload' do
    it 'raises error unless specified bot has loaded' do
      expect { subject.unload(:foo) }.to raise_error(Kubot::Manager::BotNotLoaded)
    end

    it 'calls Bot#finalize to specified bot' do
      bot = FooBot.new
      Kubot::Bot.stub(:bots_diff) { [FooBot] }
      FooBot.stub(:new){bot}

      subject.load(:foo)

      bot.should_receive(:finalize)
      subject.unload(:foo)
    end

    it "manages loaded bots using class variable, but doesn't share Bot instances" do
      bot_a, bot_b = FooBot.new, FooBot.new
      another = Kubot::Manager.new(Kubot::MOCK_LOAD_PATH)

      Kubot::Bot.stub(:bots_diff) { [FooBot] }

      FooBot.stub(:new){ bot_a }
      subject.load(:foo)

      FooBot.stub(:new){ bot_b }
      another.load(:foo)
    end

    context 'with multiple bots in single file' do
      it 'unloads all bots in a file' do
        Kubot::Bot.stub(:bots_diff) { [MaBot, MbBot] }

        [MaBot, MbBot].each do |klass|
          bot = klass.new
          bot.should_receive(:finalize)
          klass.should_receive(:new).and_return(bot)
        end

        subject.load(:multi)
        subject.unload(:multi)
      end
    end
  end

  describe '#reload' do
    it 'calls #unload first then call #load' do
      subject.should_receive(:unload).with(:not_exist).ordered
      subject.should_receive(:load).with(:not_exist, {}, {}).ordered

      subject.reload(:not_exist)
    end

    context 'when calling #unload' do
      it 'ignores Kubot::Manager::BotNotLoaded error' do
        subject.should_receive(:unload) { raise Kubot::Manager::BotNotLoaded }
        subject.stub(:load) {}
        expect { subject.reload(:foo) }.to_not raise_error
      end
    end

    it 'calls #load for all plugins which newer than when loaded before' do
      path_a = Kubot::MOCK_PATH+"/reload_a.rb"
      path_b = Kubot::MOCK_PATH+"/reload_b.rb"
      time_a = File.mtime(path_a)
      time_b = File.mtime(path_b)
      future_a = time_a+100
      future_b = time_b+100

      File.should_receive(:mtime).with(path_a).and_return(time_a, future_a, future_a)
      File.should_receive(:mtime).with(path_b).and_return(time_b, future_b, future_a)

      subject.load(:reload_a)
      subject.load(:reload_b)

      subject.should_receive(:unload).with(:reload_a).twice.ordered
      subject.should_receive(:load).with(:reload_a, {}, {}).twice.ordered
      subject.should_receive(:unload).with(:reload_b).twice.ordered
      subject.should_receive(:load).with(:reload_b, {}, {}).twice.ordered

      subject.reload
      subject.reload
    end
  end

  describe '#unload_all' do
    it 'unloads all bots that has an instance using #unload' do
      foo = FooBot.new
      FooBot.stub(:new).and_return foo
      bar = BarBot.new
      BarBot.stub(:new).and_return bar

      Kubot::Bot.stub(:bots_diff).and_return([FooBot, BarBot])
      subject.load(:foo)
      subject.load(:bar)

      foo.should_receive(:finalize)
      bar.should_receive(:finalize)
      subject.unload_all
    end
  end
end
