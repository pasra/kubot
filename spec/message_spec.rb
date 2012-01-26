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
      Kubot.validate(:message, room: "hoge", message: "hi", name: "foo")
    end

    it 'for message requires :message, :name, :room on obj' do
      Kubot.validate(:message,
                     room: "hoge", message: "hi", name: "foo") \
           .should be_a_kind_of(Hash)
      Kubot.validate(:message, message: "hi").should be_false
    end

    it 'for :enter requires :name, :room' do
      Kubot.validate(:enter, room: "hoge", name: "foo").should be_a_kind_of(Hash)
      Kubot.validate(:enter, room: "hoge").should be_false
    end

    it 'for :leave requires :name, :room' do
      Kubot.validate(:leave, room: "hoge", name: "foo").should be_a_kind_of(Hash)
      Kubot.validate(:leave, room: "hoge").should be_false
    end

    it 'for :kick, requires :name, :room, :target' do
      Kubot.validate(:kick, room: "hoge", name: "foo", target: "bar") \
           .should be_a_kind_of(Hash)
      Kubot.validate(:kick, room: "hoge", name: "foo").should be_false
    end

    it 'for :name, requires :from, :to' do
      Kubot.validate(:name, from: "foo", to: "bar").should be_a_kind_of(Hash)
      Kubot.validate(:name, from: "foo")
    end

    it 'makes modification at :message' do
      a = Kubot.validate(:message, room: "hoge", message: "hi", name: "foo")
      a[:bot].should be_false
    end
  end

  describe '.new' do
    it 'validates and raises error if validation failed' do
      Kubot::Message.validator(:new_hi) {|obj| obj  }
      expect { Kubot::Message.new(a: :b) }.to_not raise_error
      Kubot::Message.validator(:new_hi) { false }
      expect { Kubot::Message.new(a: :b) }.to raise_error(Kubot::Message::InvalidMessage)
    end

    it 'validates and apply modifications' do
      Kubot::Message.new(:message, room: "hoge", message: "hi", name: "foo") \
                    .bot.should be_false
    end

    it 'calls .validate to validate' do
      o = {from: "foo", to: "bar"}
      Kubot::Message.should_receive(:validate).with(:name, o)
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
    it 'returns true if match to specified condition(s)' do
      mes = Kubot::Message.new(:name, from: "foo", to: "bar")
      mes.match?(from: "foo").should be_true
    end

    describe 'conditions:' do
      describe 'Regexp' do
        it 'is true if the regexp matches to a message' do
          mes = Kubot::Message.new(:message, room: "hoge", message: "hi", name: "foo")
          mes.match?(/hi/).should be_true
          mes.match?(/ho/).should be_false
        end

        it 'is nil if the message does not include message' do
          mes = Kubot::Message.new(:name, from: "foo", to: "bar")
          mes.match?(/hi/).should be_nil
        end
      end

      describe 'String' do
        it 'is true if the string equals to a message' do
          mes = Kubot::Message.new(:message, room: "hoge", message: "hi", name: "foo")
          mes.match?("hi").should be_true
          mes.match?("h").should be_false
        end

        it 'is nil if the message does not include message' do
          mes = Kubot::Message.new(:name, from: "foo", to: "bar")
          mes.match?("hi").should be_nil
        end
      end

      it 'is true if the any of conditions in arguments is true' do
        mes = Kubot::Message.new(:message, room: "hoge", message: "hi", name: "foo")
        mes.match?(/h/,/u/).should be_true
        mes.match?("u","o").should be_false
        mes.match?("hi","o").should be_true
        mes.match?("ho",/h/).should be_true
        mes.match?("ho",/n/).should be_false
        mes.match?("ho",/n/, name: "foo").should be_true
      end


      describe 'Array' do
        it 'is true if the any of conditions in array is true' do
          mes = Kubot::Message.new(:message, room: "hoge", message: "hi", name: "foo")
          mes.match?([/h/,/u/]).should be_true
          mes.match?(["u","o"]).should be_false
          mes.match?(["hi","o"]).should be_true
          mes.match?(["ho",/h/]).should be_true
          mes.match?(["ho",/n/]).should be_false
          mes.match?(["ho",/n/, {name: "foo"}]).should be_true
        end
      end

      describe 'Hash' do
        describe 'key :any' do
          it 'is true if the any of conditions in array is true' do
            mes = Kubot::Message.new(:message, room: "hoge", message: "hi", name: "foo")
            mes.match?(any: [/h/,/u/]).should be_true
            mes.match?(any: ["u","o"]).should be_false
            mes.match?(any: ["hi","o"]).should be_true
            mes.match?(any: ["ho",/h/]).should be_true
            mes.match?(any: ["ho",/n/]).should be_false
            mes.match?(any: ["ho",/n/,{name: "foo"}]).should be_false
          end
        end

        describe 'key :all' do
          it 'is true if the all of conditions in array is true' do
            mes = Kubot::Message.new(:message, room: "hoge", message: "hi", name: "foo")
            mes.match?(all: [/h/,/i/]).should be_true
            mes.match?(all: [/h/,/n/]).should be_false
            mes.match?(all: ["hi","hi"]).should be_true
            mes.match?(all: ["hi",/n/]).should be_false
            mes.match?(all: ["hi",/h/]).should be_false
            mes.match?(all: ["message",{name: "foo"}]).should be_false
          end
        end

        describe 'other key' do
          before do
            @mes = Kubot::Message.new(:message, room: "hoge", message: "hi", name: "foo")
          end

          it 'is true if the value is String and the value equals to the obj[key]' do
            @mes.match?(name: "foo").should be_true
            @mes.match?(name: "bar").should be_false
          end

          it 'is true if the value is Regexp and the value matches to the obj[key]' do
            @mes.match?(name: /f/).should be_true
            @mes.match?(name: /u/).should be_false
          end

          it 'is true if the value is Array and the any conditions in array is true' do
            @mes.match?(name: ["bar", "foo"]).should be_true
            @mes.match?(name: ["bar", "hoge"]).should be_false
            @mes.match?(name: ["bar", /fo/]).should be_true
            @mes.match?(name: ["bar", /fu/]).should be_false
          end
        end

        it 'is true if the any of condition in hash is true' do
          mes = Kubot::Message.new(:message, room: "hoge", message: "hi", name: "foo")
          mes.match?(name: "foo", message: "hi").should be_true
          mes.match?(name: "foo", message: "hey").should be_true
          mes.match?(name: "bar", message: "hey").should be_false
          mes.match?(name: ["bar", "foo"], message: "hey").should be_true
          mes.match?(name: "bar", message: /h/).should be_true
          mes.match?(name: "bar", message: /n/).should be_false
        end
      end
    end
  end
end
