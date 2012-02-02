require_relative './spec_helper'
require 'kubot/message'

describe Kubot::Message do
  describe '.validator' do
    context 'with block' do
      it 'can set validator' do
        described_class.validator(:hey).should be_nil
        described_class.validator(:hey) {|obj| {hoge: :huga} }
        described_class.validator(:hey)
      end
    end

    context 'without block' do
      it 'returns validator' do
        a = -> { {foo: :bar} }
        described_class.validator(:hi, &a)
        described_class.validator(:hi).should == a
      end
    end
  end

  describe '.validate' do
    it 'calls .validator to get validator' do
      described_class.should_receive(:validator).with(:message)
      described_class.validate(:message, room: "hoge", message: "hi", name: "foo")
    end

    it 'for message requires :message, :name, :room on obj' do
      described_class.validate(:message,
                     room: "hoge", message: "hi", name: "foo") \
           .should be_a_kind_of(Hash)
      described_class.validate(:message, message: "hi").should be_false
    end

    it 'for :enter requires :name, :room' do
      described_class.validate(:enter, room: "hoge", name: "foo").should be_a_kind_of(Hash)
      described_class.validate(:enter, room: "hoge").should be_false
    end

    it 'for :leave requires :name, :room' do
      described_class.validate(:leave, room: "hoge", name: "foo").should be_a_kind_of(Hash)
      described_class.validate(:leave, room: "hoge").should be_false
    end

    it 'for :kick, requires :name, :room, :target' do
      described_class.validate(:kick, room: "hoge", name: "foo", target: "bar") \
           .should be_a_kind_of(Hash)
      described_class.validate(:kick, room: "hoge", name: "foo").should be_false
    end

    it 'for :name, requires :from, :to' do
      described_class.validate(:name, from: "foo", to: "bar").should be_a_kind_of(Hash)
      described_class.validate(:name, from: "foo")
    end

    it 'makes modification at :message' do
      a = described_class.validate(:message, room: "hoge", message: "hi", name: "foo")
      a[:bot].should == false
    end
  end

  describe '.new' do
    it 'validates and raises error if validation failed' do
      described_class.validator(:new_hi) {|obj| obj }
      expect { described_class.new(:new_hi, a: :b) }.to_not raise_error
      described_class.validator(:new_hi) {|obj| false }
      expect { described_class.new(:new_hi, a: :b) }.to raise_error(described_class::InvalidMessage)
    end

    it 'validates and apply modifications' do
      described_class.new(:message, room: "hoge", message: "hi", name: "foo") \
                    .bot.should be_false
    end

    it 'calls .validate to validate' do
      o = {from: "foo", to: "bar"}
      described_class.should_receive(:validate).with(:name, o).and_return(true)
      expect { described_class.new(:name, o) }.to_not raise_error
    end
  end

  it "'s methods end with ? return true if object's type equals method name without ?" do
    a = described_class.new(:message, room: "hoge", message: "hi", name: "foo")
    b = described_class.new(:name, from: "foo", to: "bar")
    a.message?.should be_true
    b.message?.should be_false
    a.name?.should be_false
    b.name?.should be_true
  end

  it 'has some accessors for obj' do
    mes = described_class.new(:name, from: "foo", to: "bar")
    mes.from.should == "foo"
    mes.to.should == "bar"
    mes.type.should == :name
  end

  describe '.match?' do
    it 'calls Kubot::Matcher#match?' do
      o = {from: "foo", to: "bar"}
      cond = {from: "foo"}
      matcher = Kubot::Matcher.new(o)

      Kubot::Matcher.should_receive(:new).with(o, :message).and_return(matcher)
      mes = described_class.new(:name, o)
      matcher.should_receive(:match?).with(cond).and_return(:woooo)
      mes.match?(cond).should == :woooo
    end
  end

  describe '.match' do
    it 'calls Kubot::Matcher#match' do
      o = {from: "foo", to: "bar"}
      cond = {from: "foo"}
      matcher = Kubot::Matcher.new(o)

      Kubot::Matcher.should_receive(:new).with(o, :message).and_return(matcher)
      mes = described_class.new(:name, o)
      matcher.should_receive(:match).with(cond).and_return(:woooo)
      mes.match(cond).should == :woooo
    end
  end
end
