require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/setting/setting'

describe DRbQS::Setting::Source::DataContainer do
  subject do
    DRbQS::Setting::Source::DataContainer.new(Array)
  end

  context "when setting values" do
    it "should set a value." do
      subject.one_argument 3
      subject.__data__[:one_argument].should == [3]
    end

    it "should set values." do
      subject.some_arguments 'hello', 123, 'world'
      subject.__data__[:some_arguments].should == ['hello', 123, 'world']
    end

    it "should set a value by a method with '='." do
      subject.one_argument = 3
      subject.__data__[:one_argument].should == [3]
    end

    it "should set values by a method with '='." do
      subject.some_arguments = 'hello', 123, 'world'
      subject.__data__[:some_arguments].should == ['hello', 123, 'world']
    end

    it "should delete values with a string key." do
      subject.delete_key = 'abc', 'def'
      lambda do
        subject.__delete__('delete_key')
      end.should change { subject.delete_key }.from(['abc', 'def']).to(nil)
    end

    it "should delete values with a symbol key." do
      subject.delete_key = 'abc', 'def'
      lambda do
        subject.__delete__(:delete_key)
      end.should change { subject.delete_key }.from(['abc', 'def']).to(nil)
    end

    it "should set nil." do
      subject.nil_key = nil
      subject.__data__[:nil_key].should == [nil]
    end
  end

  context "when setting arguments" do
    it "should add an argument" do
      subject.argument << 'hello'
      subject.argument.should include('hello')
    end

    it "should set argumets" do
      subject.argument = ['ABC', 'DEF']
      subject.argument.should == ['ABC', 'DEF']
    end

    it "should unshift an argument" do
      subject.argument = ['ABC', 'DEF']
      subject.argument.unshift('first')
      subject.argument.should == ['first', 'ABC', 'DEF']
    end
  end

  context "when cloning" do
    it "should have same values." do
      subject.argument = ['hello']
      subject.some_key1 = [1, 2]
      subject.some_key2 = 'ABCDE'
      container_clone = DRbQS::Setting::Source.clone_container(subject)
      subject.argument.should == container_clone.argument
    end

    it "should have a different argument." do
      subject.argument = ['hello']
      container_clone = DRbQS::Setting::Source.clone_container(subject)
      subject.argument << 'world'
      subject.argument.should_not == container_clone.argument
    end

    it "should have different values." do
      subject.key1 = 'abc'
      container_clone = DRbQS::Setting::Source.clone_container(subject)
      subject.key1 = 'def'
      subject.key1.should_not == container_clone.key1
    end
  end
end
