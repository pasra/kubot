require_relative './spec_helper'
require 'kubot/manager'
require 'tmpdir'
require_relative Kubot::MOCK_PATH+"/foo"
require_relative Kubot::MOCK_PATH+"/bar"
require_relative Kubot::MOCK_PATH+"/multi"
require_relative Kubot::MOCK_PATH+"/exist"

describe Kubot::Manager do
  #before :all do
  #  @mockdir = Dir.mktmpdir
  #end

  before :each do
    FooBot.reset if defined?(FooBot)
    #@manager = Kubot::Manager.new([@mockdir]+Kubot::MOCK_LOAD_PATH)
    @manager = Kubot::Manager.new(Kubot::MOCK_LOAD_PATH)
  end

  it 'has accessor for load path' do
    @manager.load_path.should == Kubot::MOCK_LOAD_PATH
  end

  describe '.new' do
    it 'accepts Array and Hash as load_path, bot list' do
      expect { Kubot::Manager.new(Kubot::MOCK_LOAD_PATH) }.to_not raise_error
    end
  end 

  describe '#load' do
    it 'accepts bot name, config, option' do
      expect { @manager.load(:foo) }.to_not raise_error
      expect { @manager.load(:foo, {the: :config}) }.to_not raise_error
      expect { @manager.load(:foo, {the: :config}, {db: nil}) }.to_not raise_error
    end

    it 'finds bot using load_path and start it' do
      config= {the: :config}
      option= {db: nil}
      Kernel.should_receive(:load).and_return { FooBot.should_receive(:new).with(config, option).and_return(nil) }
      @manager.load(:foo, config, option)
    end

    it 'detects bot using bots_diff' do
      Kubot::Bot.should_receive(:bots_diff).and_return([FooBot])
      FooBot.should_receive(:new).and_return(FooBot.new)
      @manager.load(:foo)
    end

    it 'reloads bot using #reload if it has already loaded' do
      @manager.should_not_receive(:reload)
      @manager.load(:foo, {the: :config})
      @manager.should_receive(:reload).with(:foo, {the: :config}).and_return(@manager)
      @manager.load(:foo, {the: :config})
    end

    it 'raises error unless bot file is found' do
      expect { @manager.load(:this_is_not_exist) }.to raise_error(Kubot::Manager::BotNotFound)
    end

    it "doesn't share Bot instances" do
      another = Kubot::Manager.new(Kubot::MOCK_LOAD_PATH)
      bot = FooBot.new
      Kubot::Bot.stub(:bots_diff) { [FooBot] }
      FooBot.should_receive(:new).and_return { bot }
      @manager.load(:foo)
      FooBot.should_receive(:new).and_return { bot }
      another.load(:foo)
    end

    it 'starts bots both already exist and added' do
      bot_a = [EaBot.new, EaBot.new]
      bot_b = EbBot.new
      Kubot::Bot.stub(:bots_diff) { [EaBot] }
      EaBot.should_receive(:new).and_return(bot_a.shift)
      @manager.load(:exist)
      Kubot::Bot.stub(:bots_diff) { [EbBot] }
      EaBot.should_receive(:new).and_return(bot_a.shift)
      EbBot.should_receive(:new).and_return(bot_b)
      @manager.load(:exist)
    end

    context 'with multiple bots in single file' do
      it 'loads all bots in a file and start all of them' do
        Kubot::Bot.stub(:bots_diff) { [MaBot, MbBot] }

        [MaBot, MbBot].each do |klass|
          klass.should_receive(:new).and_return(klass.new)
        end

        @manager.load(:multi)
      end
    end
  end

  describe '#unload' do
    it 'raises error unless specified bot has loaded' do
      expect { Kubot::Manager.new.unload(:foo) }.to raise_error(Kubot::Manager::BotNotLoaded)
    end

    it 'calls Bot#finalize to specified bot' do
      bot = FooBot.new
      Kernel.stub(:load){}
      Kubot::Bot.stub(:bots_diff) { [FooBot] }
      FooBot.stub(:new){bot}

      @manager.load(:foo)

      bot.should_receive(:finalize)
      @manager.unload(:foo)
    end

    it "manages loaded bots using class variable, but doesn't share Bot instances" do
      bot_a, bot_b = FooBot.new, FooBot.new
      another = Kubot::Manager.new(Kubot::MOCK_LOAD_PATH)

      Kernel.stub(:load){}
      Kubot::Bot.stub(:bots_diff) { [FooBot] }

      FooBot.stub(:new){ bot_a }
      @manager.load(:foo)

      FooBot.stub(:new){ bot_b }
      another.load(:foo)
    end

    context 'with multiple bots in single file' do
      it 'unloads all bots in a file' do
        Kernel.stub(:load){}
        Kubot::Bot.stub(:bots_diff) { [MaBot, MbBot] }

        [MaBot, MbBot].each do |klass|
          bot = klass.new
          bot.should_receive(:finalize)
          klass.should_receive(:new).and_return(bot)
        end

        @manager.load(:multi)
        @manager.unload(:multi)
      end
    end
  end

  describe '#reload' do
    it 'calls #unload first then call #load' do
      @manager.should_receive(:unload).with(:not_exist).ordered
      @manager.should_receive(:load).with(:not_exist).ordered

      @manager.reload(:not_exist)
    end

    context 'when calling #unload' do
      it 'ignores Kubot::Manager::BotNotLoaded error' do
        @manager.should_receive(:unload) { raise Kubot::Manager::BotNotLoaded }
        @manager.stub(:load) {}
        expect { @manager.reload(:foo) }.to_not raise_error
      end
    end
  end

  describe '#reload' do
    before :each do
      @tmpdir = Dir.mktmpdir
      FileUtils.cp("#{Kubot::MOCK_PATH}/reload_a.rb", @tmpdir)
      FileUtils.cp("#{Kubot::MOCK_PATH}/reload_b.rb", @tmpdir)
      @manager = Kubot::Manager.new([@tmpdir])
    end

    it 'calls #load for all plugins which newer than when loaded before' do
      @manager.load(:reload_a)
      @manager.load(:reload_b)

      @manager.should_not_receive(:load)
      @manager.reload

      FileUtils.touch "#{@tmpdir}/reload_a.rb"
      FileUtils.touch "#{@tmpdir}/reload_b.rb"

      @manager.should_receive(:load).with(:reload_a)
      @manager.should_receive(:load).with(:reload_b)
      @manager.reload
    end

    after :each do
      FileUtils.remove_entry_secure @tmpdir
    end
  end

  describe '#unload_all' do
    it 'unloads all bots that has an instance using #unload' do
      foo = FooBot.new
      FooBot.stub(:new){foo}
      bar = BarBot.new
      BarBot.stub(:new){bar}

      @manager.load(:foo)
      @manager.load(:bar)

      foo.should_receive(:finalize)
      bar.should_receive(:finalize)
      @manager.unload_all
    end
  end
end
