require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'drbqs/history'

describe DRbQS::History do
  subject { DRbQS::History.new }

  it "should add new id" do
    subject.begin(1, 'hello')
    ary = subject.each.to_a
    ary.should have(1).items
    ary[0][0].should == 1
    ary[0][1].should have(2).items
    ary[0][1][0].should == 'hello'
    ary[0][1][1].should be_an_instance_of Time
  end

  it "should set disconnected" do
    subject.begin(1, 'hello')
    subject.finish(1)
    ary = subject.each.to_a
    ary.should have(1).items
    ary[0][0].should == 1
    ary[0][1].should have(3).items
    ary[0][1][0].should == 'hello'
    ary[0][1][1].should be_an_instance_of Time
    ary[0][1][2].should be_an_instance_of Time
  end
end
