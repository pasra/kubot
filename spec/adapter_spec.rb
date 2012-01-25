require_relative "./spec_helper"
require "kubot/adapter"

klass= Kubot::Adapter
describe klass do
  describe ".new" do
    it 'accepts one option hash' do
      expect { klass.new(foo: :bar) }.to_not raise_error
      expect { klass.new() }.to_not raise_error
    end
  end

  describe "#open" do
    it 'sends open event' do
      adapter = klass.new
      called = false
      adapter.hook {|event, obj| called = true; event.should == :open }
      adapter.open
      called.should be_true
    end

    it 'returns itself' do
      (_ = klass.new).open.should == _
    end
  end

  describe "#close" do
    it 'raises error when it have not opened' do
      adapter = klass.new
      expect { adapter.close }.to raise_error
    end

    it 'sends close event' do
      adapter = klass.new
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

    it 'returns itself' do
      adapter = klass.new
      adapter.open; adapter.close.should == adapter
    end
  end

  describe "#hook" do
    it 'hooks for event and call at event' do
      adapter = klass.new
      called = false
      adapter.hook {|event, obj| called = true; event.should == :hi}
      adapter.fire :hi
      called.should be_true
    end

    it 'accepts multiple blocks' do
      adapter = klass.new

      called_a = false
      called_b = false

      adapter.hook {|event, obj| called_a = true; event.should == :hi}
      adapter.hook {|event, obj| called_b = true; event.should == :hi}
      adapter.fire :hi

      called_a.should be_true
      called_b.should be_true
    end

    it 'returns itself' do
      (_ = klass.new).hook{|event, obj| }.should == _
    end
  end

  describe "#fire" do
    it 'fires event and call hooks' do
      adapter = klass.new
      called = false
      adapter.hook {|event, obj| called = true; event.should == :hi }
      adapter.fire :hi, the: :option
      called.should be_true
    end

    it 'fires event with obj, and calls hooks with obj' do
      adapter = klass.new
      called = false

      adapter.hook do |event, obj|
        called = true
        event.should == :hi
        obj[:the].should == :option
      end

      adapter.fire :hi, the: :option
      called.should be_true
    end

    it 'returns itself' do
      (_=klass.new).fire(:yeah).should == _
    end
  end

  describe "#say" do
    it 'accepts room, string, option' do
      adapter = klass.new
      adapter.open
      expect { adapter.say 'room', 'hi', the: :option }.to_not raise_error
      expect { adapter.say 'room', 'hi' }.to_not raise_error
    end

    it 'raises error if not opened' do
      adapter = klass.new
      expect { adapter.say 'room', 'hi' }.to raise_error
      adapter.open
      expect { adapter.say 'room', 'hi' }.to_not raise_error
    end

    it 'returns itself' do
      adapter = klass.new
      adapter.open
      adapter.say('room', 'hi').should == adapter
    end
  end

  describe "#enter" do
    it 'returns itself' do
      adapter = klass.new
      adapter.open
      adapter.enter('room').should == adapter
    end

    it 'raises error if not opened' do
      adapter = klass.new
      expect { adapter.enter 'room' }.to raise_error
      adapter.open
      expect { adapter.enter 'room' }.to_not raise_error
    end
  end

  describe "#leave" do
    it 'returns itself' do
      adapter = klass.new
      adapter.open
      adapter.leave('room').should == adapter
    end

    it 'raises error if not opened' do
      adapter = klass.new
      expect { adapter.leave 'room' }.to raise_error
      adapter.open
      expect { adapter.leave 'room' }.to_not raise_error
    end
  end

  describe "#members_in" do
    it 'raises error if not opened' do
      adapter = klass.new
      expect { adapter.members_in 'room' }.to raise_error
      adapter.open
      expect { adapter.members_in 'room' }.to_not raise_error
    end

    it 'returns array' do
      adapter = klass.new
      adapter.open
      adapter.members_in('room').should be_a_kind_of(Array)
    end
  end
end

