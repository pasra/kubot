require_relative "./spec_helper"
require "kubot/adapter"

describe Kubot::Adapter do
  describe ".new" do
    it 'accepts one option hash' do
      expect { described_class.new(foo: :bar) }.to_not raise_error
      expect { klass.new() }.to_not raise_error
    end
  end

  describe "#open" do
    it 'sends open event' do
      called = false
      subject.hook {|event, obj| called = true; event.should == :open }
      subject.open
      called.should be_true
    end

    it 'returns itself' do
      subject.open.should == subject
    end
  end

  describe "#close" do
    it 'raises error when it have not opened' do
      expect { subject.close }.to raise_error
    end

    it 'sends close event' do
      flag = false
      called = 0
      subject.hook do |event, obj|
        called += 1
        event.should == (flag ? :close : :open)
        flag = true
      end
      subject.open; subject.close
      called.should == 2
    end

    it 'returns itself' do
      subject.open; subject.close.should == subject
    end
  end

  describe "#hook" do
    it 'hooks for event and call at event' do
      called = false
      subject.hook {|event, obj| called = true; event.should == :hi}
      subject.fire :hi
      called.should be_true
    end

    it 'accepts multiple blocks' do
      called_a = false
      called_b = false

      subject.hook {|event, obj| called_a = true; event.should == :hi}
      subject.hook {|event, obj| called_b = true; event.should == :hi}
      subject.fire :hi

      called_a.should be_true
      called_b.should be_true
    end

    it 'returns itself' do
      subject.hook{|event, obj| }.should == subject
    end
  end

  describe "#fire" do
    it 'fires event and call hooks' do
      called = false
      subject.hook {|event, obj| called = true; event.should == :hi }
      subject.fire :hi, the: :option
      called.should be_true
    end

    it 'fires event with obj, and calls hooks with obj' do
      called = false

      subject.hook do |event, obj|
        called = true
        event.should == :hi
        obj[:the].should == :option
      end

      subject.fire :hi, the: :option
      called.should be_true
    end

    it 'returns itself' do
      subject.fire(:yeah).should == subject
    end
  end

  describe "#say" do
    it 'accepts room, string, option' do
      subject.open
      expect { subject.say 'room', 'hi', the: :option }.to_not raise_error
      expect { subject.say 'room', 'hi' }.to_not raise_error
    end

    it 'raises error if not opened' do
      expect { subject.say 'room', 'hi' }.to raise_error
      subject.open
      expect { subject.say 'room', 'hi' }.to_not raise_error
    end

    it 'returns itself' do
      subject.open
      subject.say('room', 'hi').should == subject
    end
  end

  describe "#enter" do
    it 'returns itself' do
      subject.open
      subject.enter('room').should == subject
    end

    it 'raises error if not opened' do
      expect { subject.enter 'room' }.to raise_error
      subject.open
      expect { subject.enter 'room' }.to_not raise_error
    end
  end

  describe "#leave" do
    it 'returns itself' do
      subject.open
      subject.leave('room').should == subject
    end

    it 'raises error if not opened' do
      expect { subject.leave 'room' }.to raise_error
      subject.open
      expect { subject.leave 'room' }.to_not raise_error
    end
  end

  describe "#members_in" do
    it 'raises error if not opened' do
      expect { subject.members_in 'room' }.to raise_error
      subject.open
      expect { subject.members_in 'room' }.to_not raise_error
    end

    it 'returns array' do
      subject.open
      subject.members_in('room').should be_a_kind_of(Array)
    end
  end
end

