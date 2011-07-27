require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/setting/setting'

describe DRbQS::Setting::Source do
  subject do
    DRbQS::Setting::Source.new
  end

  context "when setting argument keys and values" do
    it "should return registered keys." do
      subject.register_key(:key1, :check => 1)
      subject.register_key(:key2, :bool => 1)
      subject.register_key(:key3, :default => [true])
      subject.registered_keys.sort.should == [:key1, :key2, :key3].sort
    end

    it "should set just an argument." do
      subject.register_key(:key1, :check => 1)
      subject.set(:key1, :val)
      subject.check!
      subject.get(:key1).should == [:val]
    end

    it "should set just an argument with a string key." do
      subject.register_key('key2', :check => 1)
      subject.set('key2', :val)
      subject.check!
      subject.get('key2').should == [:val]
    end

    it "should raise error with more than one arguments." do
      subject.register_key(:key3, :check => 1)
      subject.set(:key3, :val, :val2)
      lambda do
        subject.check!
      end.should raise_error DRbQS::Setting::InvalidArgument
    end

    it "should set more than two arguments." do
      subject.register_key(:key4, :check => [:>, 2])
      subject.set(:key4, 1, 2, 3)
      subject.check!
      subject.get(:key4).should == [1, 2, 3]
    end

    it "should raise error with less than three arguments." do
      subject.register_key(:key5, :check => [:>, 2])
      subject.set(:key5, 1, 2)
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

    it "should get first element." do
      subject.register_key(:key, :check => 1)
      subject.set(:key, 'first')
      subject.check!
      subject.get_first(:key).should == 'first'
    end

    it "should get after processing by block." do
      subject.register_key(:key, :check => 2)
      subject.set(:key, 'hello', 'world')
      subject.check!
      subject.get(:key) do |val|
        val.join(' ')
      end.should == 'hello world'
    end

    it "should get first element after processing by block." do
      subject.register_key(:key, :check => 2)
      subject.set(:key, 'hello', 'world')
      subject.check!
      subject.get_first(:key) do |first|
        first + ' ' + first
      end.should == 'hello hello'
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

  context "when cloning an object" do
    before(:all) do
      subject.register_key(:key1, :check => [:>, 1])
      subject.register_key(:key2, :bool => true)
      subject.register_key(:key3, :add => true)
      subject.register_key(:key4, :default => [1, 2, 3])
      @source_new = subject.clone
    end

    it "should have different @cond." do
      obj_new = @source_new.instance_variable_get(:@cond)
      obj_old = subject.instance_variable_get(:@cond)
      obj_new.should == obj_old
      obj_new.object_id.should_not == obj_old.object_id
    end

    it "should have different @default." do
      obj_new = @source_new.instance_variable_get(:@default)
      obj_old = subject.instance_variable_get(:@default)
      obj_new.should == obj_old
      obj_new.object_id.should_not == obj_old.object_id
    end

    it "should have different @value." do
      obj_new = @source_new.instance_variable_get(:@value)
      obj_old = subject.instance_variable_get(:@value)
      [:key1, :key2, :key3, :key4].each do |k|
        obj_new.__send__(k).should == obj_old.__send__(k)
      end
    end

    it "should have different @argument_condition." do
      obj_new = @source_new.instance_variable_get(:@argument_condition)
      obj_old = subject.instance_variable_get(:@argument_condition)
      obj_new.should == obj_old
    end

    it "should have same value of @all_keys_defined." do
      @source_new.instance_variable_get(:@all_keys_defined).should ==
        subject.instance_variable_get(:@all_keys_defined)
    end
  end

  context "when converting to an array of command line arguments" do
    it "should return boolean options." do
      subject.register_key(:a, :bool => true)
      subject.register_key(:bc, :bool => true)
      subject.set(:a)
      subject.set(:bc)
      subject.command_line_argument.should == ['-a', '--bc']
    end

    it "should return short options." do
      subject.register_key(:a)
      subject.set(:a, 'val1', 'val2')
      subject.command_line_argument.should == ['-a', 'val1', '-a', 'val2']
    end

    it "should return long options." do
      subject.register_key(:long)
      subject.set(:long, 'val1', 'val2')
      subject.command_line_argument.should == ['--long', 'val1', '--long', 'val2']
    end

    it "should replace '_' by '-'." do
      subject.register_key(:long_opts)
      subject.set(:long_opts, 'val1', 'val2')
      subject.command_line_argument.should == ['--long-opts', 'val1', '--long-opts', 'val2']
    end

    it "should escape strings." do
      subject.register_key(:long)
      subject.set(:long, 'val1', 'val"2')
      subject.command_line_argument(true).should == ['--long', '"val1"', '--long', '"val\"2"']
    end

    it "should return arguments." do
      subject.set_argument(1, 23, 'a')
      subject.command_line_argument.should == ['1', '23', 'a']
    end

    it "should escape arguments." do
      subject.set_argument(1, 23, 'a"bc')
      subject.command_line_argument(true).should == ['"1"', '"23"', '"a\"bc"']
    end
  end
end
