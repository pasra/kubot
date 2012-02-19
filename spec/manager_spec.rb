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
    it 'accepts Array and Hash as load_path, bot list' do
      expect { Kubot::Manager.new(Kubot::MOCK_LOAD_PATH) }.to_not raise_error
    end
  end 

  describe '#load' do
    it 'accepts bot name, config, option' do
      expect { subject.load(:foo) }.to_not raise_error
      expect { subject.load(:foo, {the: :config}) }.to_not raise_error
      expect { subject.load(:foo, {the: :config}, {db: nil}) }.to_not raise_error
    end

    it 'finds bot using load_path and start it' do
      config= {the: :config}
      option= {db: nil}
      Kernel.should_receive(:load).and_return { FooBot.should_receive(:new).with(config, option).and_return(nil) }
      subject.load(:foo, config, option)
    end

    it 'detects bot using bots_diff' do
      Kubot::Bot.should_receive(:bots_diff).and_return([FooBot])
      FooBot.should_receive(:new).and_return(FooBot.new)
      subject.load(:foo)
    end

    it 'reloads bot using #reload if it has already loaded' do
      should_not_receive(:reload)
      subject.load(:foo, {the: :config})
      should_receive(:reload).with(:foo, {the: :config}).and_return(subject)
      subject.load(:foo, {the: :config})
    end

    it 'raises error unless bot file is found' do
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
          klass.should_receive(:new).and_return(klass.new)
        end

        subject.load(:multi)
      end
    end
  end

  describe '#unload' do
    it 'raises error unless specified bot has loaded' do
      expect { Kubot::Manager.new.unload(:foo) }.to raise_error(Kubot::Manager::BotNotLoaded)
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
      should_receive(:unload).with(:not_exist).ordered
      should_receive(:load).with(:not_exist).ordered

      subject.reload(:not_exist)
    end

    context 'when calling #unload' do
      it 'ignores Kubot::Manager::BotNotLoaded error' do
        should_receive(:unload) { raise Kubot::Manager::BotNotLoaded }
        subject.stub(:load) {}
        expect { subject.reload(:foo) }.to_not raise_error
      end
    end
  end

  describe '#reload' do
    before :each do
      @tmpdir = Dir.mktmpdir
      FileUtils.cp("#{Kubot::MOCK_PATH}/reload_a.rb", @tmpdir)
      FileUtils.cp("#{Kubot::MOCK_PATH}/reload_b.rb", @tmpdir)
    end

    subject { Kubot::Manager.new([@tmpdir]) }

    it 'calls #load for all plugins which newer than when loaded before' do
      subject.load(:reload_a)
      subject.load(:reload_b)

      should_not_receive(:load)
      should_not_receive(:unload)
      subject.reload

      FileUtils.touch "#{@tmpdir}/reload_a.rb"
      FileUtils.touch "#{@tmpdir}/reload_b.rb"

      should_receive(:unload).with(:reload_a)
      should_receive(:unload).with(:reload_b)
      should_receive(:load).with(:reload_a)
      should_receive(:load).with(:reload_b)
      subject.reload
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

      subject.load(:foo)
      subject.load(:bar)

      foo.should_receive(:finalize)
      bar.should_receive(:finalize)
      subject.unload_all
    end
  end
end
