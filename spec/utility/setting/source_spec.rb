require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'drbqs/utility/setting/source'

describe DRbQS::Setting::Source do
  subject do
    DRbQS::Setting::Source.new
  end

  context "when setting argument keys and values" do
    it "should set just an argument.." do
      subject.register_key(:key, :check => 1)
      subject.set(:key, :val)
      subject.get(:key).should == [:val]
    end

    it "should raise error with more than one arguments." do
      subject.register_key(:key, :check => 1)
      lambda do
        subject.set(:key, :val, :val2)
      end.should raise_error
    end

    it "should set more than two arguments." do
      subject.register_key(:key, :check => [:>, 2])
      subject.set(:key, 1, 2, 3)
      subject.get(:key).should == [1, 2, 3]
    end

    it "should raise error with less than three arguments." do
      subject.register_key(:key, :check => [:>, 2])
      lambda do
        subject.set(:key, 1, 2)
      end.should raise_error
    end

   it "should set arguments with multiple conditions." do
      subject.register_key(:key, :check => [:>, 2, :<=, 4])
      subject.set(:key, 1, 2, 3, 4)
      subject.get(:key).should == [1, 2, 3, 4]
    end

   it "should raise error for second condition." do
      subject.register_key(:key, :check => [:>, 2, :<=, 4])
      lambda do
        subject.set(:key, 1, 2, 3, 4, 5)
      end.should raise_error
    end

    it "should set some arguments" do
      subject.register_key(:key1, :check => 1)
      subject.register_key(:key2, :check => [:>, 1])
      subject.set(:key1, 3)
      subject.set(:key2, 2, 4)
      subject.get(:key1).should == [3]
      subject.get(:key2).should == [2, 4]
    end

    it "should cancel an argument set before." do
      subject.register_key(:key, :check => 1)
      subject.set(:key, 1)
      subject.set(:key, 2)
      subject.get(:key).should == [2]
    end

    it "should add an arguments." do
      subject.register_key(:key, :add => true)
      subject.set(:key, 1)
      subject.set(:key, 2)
      subject.get(:key).should == [1, 2]
    end

    it "should set default value." do
      subject.register_key(:key, :default => [0])
      lambda do
        subject.set(:key, 10)
      end.should change { subject.get(:key) }.from([0]).to([10])
    end

    it "should clear value." do
      subject.register_key(:key, :check => 1)
      subject.set(:key, 1)
      subject.clear(:key)
      subject.get(:key).should be_nil
    end
  end

  context "when setting arguments" do
    it "should set arguments" do
      subject.set_argument(1, 2, 3)
      subject.argument.should == [1, 2, 3]
    end

    it "should set arguments with checking." do
      subject.check_argument(3)
      subject.set_argument(1, 2, 3)
      subject.argument.should == [1, 2, 3]
    end

    it "should raise error for invalid arguments." do
      subject.check_argument(:>, 1)
      lambda do
        subject.set_argument(1)
      end.should raise_error
    end
  end

end
