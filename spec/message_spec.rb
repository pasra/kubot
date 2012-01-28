require_relative './spec_helper'
require 'kubot/message'

describe Kubot::Message do
  describe '.validator' do
    context 'with block' do
      it 'can set validator' do
        Kubot::Message.validator(:hey).should be_nil
        Kubot::Message.validator(:hey) {|obj| {hoge: :huga} }
        Kubot::Message.validator(:hey)
      end
    end

    context 'without block' do
      it 'returns validator' do
        a = -> { {foo: :bar} }
        Kubot::Message.validator(:hi, &a)
        Kubot::Message.validator(:hi).should == a
      end
    end
  end

  describe '.validate' do
    it 'calls .validator to get validator' do
      Kubot::Message.should_receive(:validator).with(:message)
      Kubot::Message.validate(:message, room: "hoge", message: "hi", name: "foo")
    end

    it 'for message requires :message, :name, :room on obj' do
      Kubot::Message.validate(:message,
                     room: "hoge", message: "hi", name: "foo") \
           .should be_a_kind_of(Hash)
      Kubot::Message.validate(:message, message: "hi").should be_false
    end

    it 'for :enter requires :name, :room' do
      Kubot::Message.validate(:enter, room: "hoge", name: "foo").should be_a_kind_of(Hash)
      Kubot::Message.validate(:enter, room: "hoge").should be_false
    end

    it 'for :leave requires :name, :room' do
      Kubot::Message.validate(:leave, room: "hoge", name: "foo").should be_a_kind_of(Hash)
      Kubot::Message.validate(:leave, room: "hoge").should be_false
    end

    it 'for :kick, requires :name, :room, :target' do
      Kubot::Message.validate(:kick, room: "hoge", name: "foo", target: "bar") \
           .should be_a_kind_of(Hash)
      Kubot::Message.validate(:kick, room: "hoge", name: "foo").should be_false
    end

    it 'for :name, requires :from, :to' do
      Kubot::Message.validate(:name, from: "foo", to: "bar").should be_a_kind_of(Hash)
      Kubot::Message.validate(:name, from: "foo")
    end

    it 'makes modification at :message' do
      a = Kubot::Message.validate(:message, room: "hoge", message: "hi", name: "foo")
      a[:bot].should == false
    end
  end

  describe '.new' do
    it 'validates and raises error if validation failed' do
      Kubot::Message.validator(:new_hi) {|obj| obj }
      expect { Kubot::Message.new(:new_hi, a: :b) }.to_not raise_error
      Kubot::Message.validator(:new_hi) {|obj| false }
      expect { Kubot::Message.new(:new_hi, a: :b) }.to raise_error(Kubot::Message::InvalidMessage)
    end

    it 'validates and apply modifications' do
      Kubot::Message.new(:message, room: "hoge", message: "hi", name: "foo") \
                    .bot.should be_false
    end

    it 'calls .validate to validate' do
      o = {from: "foo", to: "bar"}
      Kubot::Message.should_receive(:validate).with(:name, o).and_return(true)
      expect { Kubot::Message.new(:name, o) }.to_not raise_error
    end
  end

  it "'s methods end with ? return true if object's type equals method name without ?" do
    a = Kubot::Message.new(:message, room: "hoge", message: "hi", name: "foo")
    b = Kubot::Message.new(:name, from: "foo", to: "bar")
    a.message?.should be_true
    b.message?.should be_false
    a.name?.should be_false
    b.name?.should be_true
  end

  it 'has some accessors for obj' do
    mes = Kubot::Message.new(:name, from: "foo", to: "bar")
    mes.from.should == "foo"
    mes.to.should == "bar"
    mes.type.should == :name
  end

  describe '.match?' do
    it 'calls Kubot::Matcher#match?' do
      o = {from: "foo", to: "bar"}
      cond = {from: "foo"}
      matcher = Kubot::Matcher.new(o)

      Kubot::Matcher.should_receive(:new).with(o).and_return(matcher)
      mes = Kubot::Message.new(:name, o)
      matcher.should_receive(:match?).with(cond).and_return(:woooo)
      mes.match?(cond).should == :woooo
    end
  end

  describe '.match' do
    it 'calls Kubot::Matcher#match' do
      o = {from: "foo", to: "bar"}
      cond = {from: "foo"}
      matcher = Kubot::Matcher.new(o)

      Kubot::Matcher.should_receive(:new).with(o).and_return(matcher)
      mes = Kubot::Message.new(:name, o)
      matcher.should_receive(:match).with(cond).and_return(:woooo)
      mes.match(cond).should == :woooo
    end
  end
end
