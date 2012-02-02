# matcher_spec.rb - spec of matcher.rb

# Original: https://github.com/sorah/sandbox/blob/master/ruby/matcher/matcher_spec.rb
# Original Author: Shota Fukumori (sora_h)
# License: Public domain

require_relative './spec_helper'
require 'kubot/matcher'

describe Kubot::Matcher do
  subject { described_class.new(foo: "bar", bar: "foo") }

  describe ".new" do
    it 'accepts target object and default key for matching' do
      expect { described_class.new(hi: :hey) }.to_not raise_error
      expect { described_class.new({hi: :hey}, :hi) }.to_not raise_error
    end
  end

  describe "#match?" do
    it 'accepts multiple arguments' do
      expect { subject.match?("baa","bar") }.to_not raise_error
      expect { subject.match?("baa") }.to_not raise_error
    end

    it 'calls #match' do
      should_receive(:match).with(["bar"]).and_return([true])
      should be_match("bar")
      should_receive(:match).with(["bar","baz"]).and_return([true])
      should be_match("bar", "baz")
    end

    it 'returns boolean' do
      should be_match(/ba/)
      should_not be_match(/bo/)
      should be_match("bar")
      should_not be_match("baa")
    end
  end

  describe '#match' do
    it 'accepts multiple arguments' do
      expect { subject.match("baa","bar") }.to_not raise_error
      expect { subject.match("baa") }.to_not raise_error
    end

    it 'accepts Regexp to check match with default key' do
      subject.match(/ba/).should be_a_kind_of(Array)
      should_not be_match(/bo/)
    end

    it 'accepts Regexp and return matchdatas' do
      r = subject.match(/ba/)
      r.should be_a_kind_of(Array)
      r.first.should be_a_kind_of(MatchData)
    end

    it 'accepts other to check equal with the default key' do
      subject.match("bar").should be_a_kind_of(Array)
      subject.match("bar").first.should == "bar"
      should_not be_match("baa")
    end

    it 'accepts other and return array' do
      r = subject.match("bar")
      r.should be_a_kind_of(Array)
      r.should_not be_empty
      r.first.should == "bar"
    end

    describe 'with multiple arguments' do
      it 'checks is any conditions in argumens is true' do
        subject.match("baa", "bar").should be_a_kind_of(Array)
        subject.match("baa", "bar").first.should == "bar"
        subject.match("baa", /b/).should be_a_kind_of(Array)
        subject.match("baa", /b/).first.should be_a_kind_of(MatchData)
        subject.match(/fo/, /ba/).should be_a_kind_of(Array)
        subject.match("baa", "bar").first.should == "bar"
        should_not be_match(/far/, /baz/)
      end
    end

    describe 'with mixed type of arguments' do
      it 'returns array includes MatchData only' do
        subject.match("baa", /b/).should be_a_kind_of(Array)
        subject.match("baa", /b/).size.should == 1
        subject.match("baa", /b/).first.should be_a_kind_of(MatchData)
      end
    end

    it 'checks is any conditions in array is true' do
      subject.match(["baa", "bar"]).should be_a_kind_of(Array)
      subject.match(["baa", "bar"]).first.should == "bar"
      subject.match(["baa", /b/]).should be_a_kind_of(Array)
      subject.match(["baa", /b/]).first.should be_a_kind_of(MatchData)
      subject.match([/fo/, /ba/]).should be_a_kind_of(Array)
      subject.match([/fo/, /ba/]).first.should be_a_kind_of(MatchData)
      should_not be_match(["baa", "baz"])
    end

    describe 'with Hash' do
      it "checks is any key&value true" do
        subject.match(foo: "bar", bar: "bar").should be_a_kind_of(Array)
        subject.match(foo: "bar", bar: "bar").first.should == {foo: "bar"}

        r = subject.match(foo: /b/, bar: "bar")
        r.should be_a_kind_of(Array)
        r.first.keys[0].should == :foo
        r.first[:foo].should be_a_kind_of(MatchData)

        r = subject.match(foo: /b/, bar: /ba/)
        r.should be_a_kind_of(Array)
        r.first.keys[0].should == :foo
        r.first[:foo].should be_a_kind_of(MatchData)

        should_not be_match(foo: /f/, bar: /ba/)
        should_not be_match(foo: "b", bar: /ba/)
      end

      it "checks does specified value (Regexp) matchs to obj[key]" do
        subject.match(foo: /b/).should be_a_kind_of(Array)
        subject.match(foo: /b/).first.should be_a_kind_of(Hash)
        subject.match(foo: /b/).first[:foo].should be_a_kind_of(MatchData)
        should_not be_match(foo: /f/)
      end

      it "checks does obj[key] equals to specified value (if value is not Regexp)" do
        r = subject.match(bar: "foo")
        r.should be_a_kind_of(Array)
        r.first.should be_a_kind_of(Hash)
        r.first[:bar].should  == "foo"

        should_not be_match(bar: "bar")
      end

      it 'checks is any conditions in specified value (Array) true' do
        r = subject.match(foo: ["foo", "bar"])
        r.should be_a_kind_of(Array)
        r.first.should be_a_kind_of(Hash)
        r.first[:foo].should == "bar"

        r = subject.match(foo: ["bar", /b/])
        r.should be_a_kind_of(Array)
        r.first.should be_a_kind_of(Hash)
        r.first[:foo].should == "bar"
        r.size.should == 1

        should_not be_match(foo: ["foo", /baz/])
        should_not be_match(bar: ["bar", "baz"])
      end

      it 'checks is all conditions in key :all is true' do
        subject.match(all: [{foo: "bar"}, {bar: "foo"}]).should be_a_kind_of(Array)
        subject.match(all: {foo: "bar", bar: "foo"}).should be_a_kind_of(Array)
        should_not be_match(all: [{foo: "foo"}, {bar: "foo"}])
        should_not be_match(all: {foo: "foo", bar: "foo"})
        subject.match(all: {foo: "bar", any: {foo: "foo", bar: "foo"}}).should be_a_kind_of(Array)
      end

      it 'checks is any conditions in key :any is true' do
        subject.match(any: [{foo: "bar"}, {bar: "foo"}]).should be_a_kind_of(Array)
        subject.match(any: {foo: "bar", bar: "foo"}).should be_a_kind_of(Array)
        subject.match(any: [{foo: "foo"}, {bar: "foo"}]).should be_a_kind_of(Array)
        should_not be_match(any: {foo: "foo", bar: "foo"})
        subject.match(any: {foo: "bar", any: {foo: "foo", bar: "foo"}}).should be_a_kind_of(Array)
      end

      it "checks equal to specified value if the hash only has :raw key" do
        matcher = described_class.new(foo: [1,2,3])
        matcher.match(foo: {raw: [1,2,3]}).should be_a_kind_of(Array)
        should_not be_match(foo: {raw: [1,2,3], foo: "bar"})
      end
    end

    describe 'returns a Hash:' do
      it 'has only one Hash in the last of array' do
        r = subject.match(all: [{foo: "bar"}, {bar: "foo"}])
        r.should be_a_kind_of(Array)
        r.size.should == 1
        r.last.should be_a_kind_of(Hash)
        r.last[:foo].should == "bar"
        r.last[:bar].should == "foo"

        subject.match(all: ["bar", {foo: "bar"}, {bar: "foo"}]).last.should be_a_kind_of(Hash)
      end

      it 'has Array for a value when a key has multiple matches' do
        r = subject.match(all: {foo: [/b/,/a/,/r/]})
        r.last[:foo].should be_a_kind_of(Array)
        r.last[:foo].size.should == 3
      end
    end
  end
end
