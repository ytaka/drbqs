require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/setting/source'

describe DRbQS::Setting::Source::DataContainer do
  subject do
    DRbQS::Setting::Source::DataContainer.new(Array)
  end

  context "when setting values" do
    it "should set a value." do
      subject.one_argument = 3
      subject.__data__[:one_argument].should == [3]
    end

    it "should set a value." do
      subject.some_arguments = 'hello', 123, 'world'
      subject.__data__[:some_arguments].should == ['hello', 123, 'world']
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
end


describe DRbQS::Setting::Source do
  subject do
    DRbQS::Setting::Source.new
  end

  context "when setting argument keys and values" do
    it "should set just an argument.." do
      subject.register_key(:key, :check => 1)
      subject.set(:key, :val)
      subject.check!
      subject.get(:key).should == [:val]
    end

    it "should raise error with more than one arguments." do
      subject.register_key(:key, :check => 1)
      subject.set(:key, :val, :val2)
      lambda do
        subject.check!
      end.should raise_error DRbQS::Setting::InvalidArgument
    end

    it "should set more than two arguments." do
      subject.register_key(:key, :check => [:>, 2])
      subject.set(:key, 1, 2, 3)
      subject.check!
      subject.get(:key).should == [1, 2, 3]
    end

    it "should raise error with less than three arguments." do
      subject.register_key(:key, :check => [:>, 2])
      subject.set(:key, 1, 2)
      lambda do
        subject.check!
      end.should raise_error DRbQS::Setting::InvalidArgument
    end

   it "should set arguments with multiple conditions." do
      subject.register_key(:key, :check => [:>, 2, :<=, 4])
      subject.set(:key, 1, 2, 3, 4)
      subject.get(:key).should == [1, 2, 3, 4]
    end

   it "should raise error for second condition." do
      subject.register_key(:key, :check => [:>, 2, :<=, 4])
      subject.set(:key, 1, 2, 3, 4, 5)
      lambda do
        subject.check!
      end.should raise_error DRbQS::Setting::InvalidArgument
    end

    it "should set some arguments" do
      subject.register_key(:key1, :check => 1)
      subject.register_key(:key2, :check => [:>, 1])
      subject.set(:key1, 3)
      subject.set(:key2, 2, 4)
      subject.check!
      subject.get(:key1).should == [3]
      subject.get(:key2).should == [2, 4]
    end

    it "should cancel an argument set before." do
      subject.register_key(:key, :check => 1)
      subject.set(:key, 1)
      subject.set(:key, 2)
      subject.check!
      subject.get(:key).should == [2]
    end

    it "should add an arguments." do
      subject.register_key(:key, :add => true)
      subject.set(:key, 1)
      subject.set(:key, 2)
      subject.check!
      subject.get(:key).should == [1, 2]
    end

    it "should set default value." do
      subject.register_key(:key, :default => [0])
      lambda do
        subject.set(:key, 10)
        subject.check!
      end.should change { subject.get(:key) }.from([0]).to([10])
    end

    it "should clear value." do
      subject.register_key(:key, :check => 1)
      subject.set(:key, 1)
      subject.check!
      subject.clear(:key)
      subject.get(:key).should be_nil
    end

    it "should set by [key]=() method." do
      subject.register_key(:key, :check => [:>, 2])
      subject[:key] = 1, 2, 3
      subject.check!
      subject.get(:key).should == [1, 2, 3]
    end

    it "should get by [key] method." do
      subject.register_key(:key, :check => [:>, 2])
      subject[:key] = 1, 2, 3
      subject.check!
      subject[:key].should == [1, 2, 3]
    end
  end

  context "when setting arguments" do
    it "should set arguments" do
      subject.set_argument(1, 2, 3)
      subject.get_argument.should == [1, 2, 3]
    end

    it "should set arguments with checking." do
      subject.set_argument_condition(3)
      subject.set_argument(1, 2, 3)
      subject.check!
      subject.get_argument.should == [1, 2, 3]
    end

    it "should raise error for invalid arguments." do
      subject.set_argument_condition(:>, 1)
      subject.set_argument(1)
      lambda do
        subject.check!
      end.should raise_error DRbQS::Setting::InvalidArgument
    end
  end

end
