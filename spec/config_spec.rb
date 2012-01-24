require_relative "./spec_helper"
require "kubot/config"

sample = "#{File.dirname(__FILE__)}/sample_config.yml"

describe Kubot::Config do
  it "loads from yaml file" do
    expect { Kubot::Config.new(sample) }.to_not raise_error
  end

  it "keys converted into Symbols" do
    c = Kubot::Config.new(sample)
    c[:a].should == "hi"
  end

  it "keys converted recursively" do
    c = Kubot::Config.new(sample)
    c[:b][:c][:foo].should == "bar"
    c[:b][:c][:hoge].should == "huga"
    c[:b][:d][0].should == "a"
    c[:b][:d][1][:b].should == "c"
    c[:b][:d][1][:d].should == "e"
    c[:c][0][:d].should == "e"
    c[:c][0][:f].should == "g"
    c[:c][1][:h].should == "i"
    c[:c][1][:j].should == "k"
    c[:c][2].should == "l"
  end

  it "can be accesable by method" do
    c = Kubot::Config.new(sample)
    c.b.c.foo.should == "bar"
    c.b.c.hoge.should == "huga"
    c.b.d[0].should == "a"
    c.b.d[1].b.should == "c"
    c.b.d[1].d.should == "e"
    c.c[0].d.should == "e"
    c.c[0].f.should == "g"
    c.c[1].h.should == "i"
    c.c[1].j.should == "k"
    c.c[2].should == "l"
  end
end
