# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/worker/serialize'

describe DRbQS::Worker::Serialize::Unpacker do
  before(:all) do
    @unpacker = DRbQS::Worker::Serialize::Unpacker.new
  end

  subject do
    @unpacker
  end

  it "should dump." do
    s = "abcあいうえお"
    DRbQS::Worker::Serialize.dump(s).should be_an_instance_of String
  end

  it "should unpack." do
    orig = "abcあいうえお"
    subject.feed(DRbQS::Worker::Serialize.dump(orig))
    ary = subject.each.to_a
    ary.should have(1).item
    ary[0].should == orig
  end

  it "should split data string." do
    orig = "abcあいうえお"
    s = DRbQS::Worker::Serialize.dump(orig)
    subject.feed(s[0, 4])
    subject.each.to_a.should be_empty
    subject.feed(s[4..-1])
    ary = subject.each.to_a
    ary.should have(1).item
    ary[0].should == orig
  end

  it "should split data string (2)." do
    orig = "abcあいうえお"
    s = DRbQS::Worker::Serialize.dump(orig)
    subject.feed(s[0, 7])
    subject.each.to_a.should be_empty
    subject.feed(s[7..-1])
    ary = subject.each.to_a
    ary.should have(1).item
    ary[0].should == orig
  end

  it "should unpack multiple objects." do
    orig = [123, "abcあいうえお", -918, :sym]
    orig.each do |obj|
      subject.feed(DRbQS::Worker::Serialize.dump(obj))
    end
    ary = subject.each.to_a
    ary.should have(4).items
    ary.should == orig
  end

  it "should unpack multiple objects (2)." do
    orig = [123, "abcあいうえお", -918, :sym]
    s = ''
    orig.each do |obj|
      s << DRbQS::Worker::Serialize.dump(obj)
    end
    subject.feed(s[0, 10])
    ary = subject.each.to_a
    subject.feed(s[10..-1])
    ary.concat(subject.each.to_a)
    ary.should have(4).items
    ary.should == orig
  end
end
