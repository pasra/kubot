require_relative './spec_helper'
require 'kubot/bot'
require 'kubot/message'

valid_message = ->(message, o={}) do
  Kubot::Message.new(:message, {message: message, room: "foo", name: "bar"}.merge(o))
end

describe Kubot::Bot do
  before :each do
    @bot = Class.new(Kubot::Bot)
  end

  describe '.respond' do
    it 'makes that `fire` calls given block when matches to condition' do
      count = 0
      @bot.respond("hi"){ count += 1 }

      bot = @bot.new

      message_a = valid_message["hi"]
      message_b = valid_message["ho"]

      message_a.should_receive(:match).with("hi").and_return(["hi"])
      bot.fire message_a
      message_b.should_receive(:match).with("hi").and_return(false)
      bot.fire message_b

      count.should == 1
    end
  end

  describe '#fire' do
    it 'calls responders that matches to conditions by .respond' do
      count_a, count_b, count_c = 0, 0, 0
      ba,bb,bc = nil,nil,nil

      @bot.respond("hi") {|a,b,c| ba,bb,bc=a,b,c; count_a += 1 }
      @bot.respond(/h/)  { count_b += 1 }
      @bot.respond(/i/)  { count_c += 1 }

      bot = @bot.new
      message_a = valid_message["hi"]
      message_b = valid_message["h"]
      message_c = valid_message["i"]

      message_a.should_receive(:match).with("hi").and_return(["hi"])
      message_a.should_receive(:match).with(/h/).and_return(["hi".match(/h/)])
      message_a.should_receive(:match).with(/i/).and_return(["hi".match(/i/)])
      bot.fire message_a

      message_b.should_receive(:match).with("hi").and_return(false)
      message_b.should_receive(:match).with(/h/).and_return(["h".match(/h/)])
      message_b.should_receive(:match).with(/i/).and_return(false)
      bot.fire message_b

      message_c.should_receive(:match).with("hi").and_return(false)
      message_c.should_receive(:match).with(/h/).and_return(false)
      message_c.should_receive(:match).with(/i/).and_return(["i".match(/i/)])
      bot.fire message_c

      count_a.should == 1
      count_b.should == 2
      count_c.should == 2

      ba.should == bot
      bb.should == message_a
      bc.should == ["hi"]
    end

    it 'calls on_* method' do
      bot = @bot.new

      mes = valid_message["hi"]
      bot.should_receive(:on_message).with(mes)
      bot.fire mes

      mes = Kubot::Message.new(:test, foo: :bar)
      bot.should_receive(:on_test).with(mes)
      bot.fire mes
    end

    it 'raises no error if on_* method is not defined' do
      bot = @bot.new
      bot.respond_to?(:on_message).should be_false
      expect { bot.fire valid_message["hi"] }.to_not raise_error
    end
  end

  describe '.reset' do
    it 'clears all responder' do
      count_aa, count_ab = 0,0
      count_ba, count_bb = 0,0

      @bot.respond("hi"){ count_aa += 1}
      @bot.respond("hi"){ count_ab += 1}

      bot = @bot.new
      bot.fire valid_message["hi"]

      @bot.reset

      @bot.respond("hi"){ count_ba += 1}
      @bot.respond("hi"){ count_bb += 1}

      bot = @bot.new
      bot.fire valid_message["hi"]

      count_aa.should == 1
      count_ab.should == 1
      count_ba.should == 1
      count_bb.should == 1
    end

    it 'returns itself' do
      @bot.reset.should == @bot
    end
  end

  describe '.new' do
    it 'accepts option and config' do
      bot = @bot.new({bar: :foo, db: :hi}, {foo: :bar})
      bot.config.should == {foo: :bar}
      bot.db.should == :hi
    end
  end

  describe '.bots' do
    it 'returns array of bots that inherited this class' do
      klass = Class.new(Kubot::Bot)
      Kubot::Bot.bots.should be_a_kind_of(Array)
      Kubot::Bot.bots.should include(klass)
    end
  end

  describe '.bots_diff' do
    it 'yields and return diff of .bots before yield and after' do
      ary_ = ('a'..'z').map(&:to_sym)
      ary = []
      Kubot::Bot.stub(:bots) { ary << ary_.shift }

      flag = false
      Kubot::Bot.bots_diff { flag = true }.should == [:b]
    end
  end
end
