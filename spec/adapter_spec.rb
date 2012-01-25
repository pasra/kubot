require_relative "./spec_helper"
require "kubot/adapter"

describe Kubot::Adapter do
  describe ".new" do
    it 'accepts one option hash' do
      expect { Kubot::Adapter.new(foo: :bar) }.to_not raise_error
      expect { Kubot::Adapter.new() }.to_not raise_error
    end
  end

  describe "#open" do
    it 'sends open event' do
      adapter = Kubot::Adapter.new
      called = false
      adapter.hook {|event, obj| called = true; event.should == :open }
      adapter.open
      called.should be_true
    end
  end

  describe "#close" do
    it 'raises error when it have not opened' do
      adapter = Kubot::Adapter.new
      expect { adapter.close }.to raise_error
    end

    it 'sends close event' do
      adapter = Kubot::Adapter.new
      flag = false
      called = 0
      adapter.hook do |event, obj|
        called += 1
        event.should == (flag ? :close : :open)
        flag = true
      end
      adapter.open; adapter.close
      called.should == 2
    end
  end

  describe "#hook" do
    it 'hooks for event and call at event' do
      adapter = Kubot::Adapter.new
      called = false
      adapter.hook {|event, obj| called = true; event.should == :hi}
      adapter.fire :hi
      called.should be_true
    end

    it 'accepts multiple blocks' do
      adapter = Kubot::Adapter.new

      called_a = false
      called_b = false

      adapter.hook {|event, obj| called_a = true; event.should == :hi}
      adapter.hook {|event, obj| called_b = true; event.should == :hi}
      adapter.fire :hi

      called_a.should be_true
      called_b.should be_true
    end
  end

  describe "#fire" do
    it 'fires event and call hooks' do
      adapter = Kubot::Adapter.new
      called = false
      adapter.hook {|event, obj| called = true; event.should == :hi }
      adapter.fire :hi, the: :option
      called.should be_true
    end

    it 'fires event with obj, and calls hooks with obj' do
      adapter = Kubot::Adapter.new
      called = false

      adapter.hook do |event, obj|
        called = true
        event.should == :hi
        obj[:the].should == :option
      end

      adapter.fire :hi, the: :option
      called.should be_true
    end
  end

  describe "#say" do
    it 'accepts room, string, option' do
      adapter = Kubot::Adapter.new
      expect { adapter.say 'room', 'hi', the: :option }.to_not raise_error
    end
  end
end

