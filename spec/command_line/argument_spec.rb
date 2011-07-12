require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/command_line'

describe DRbQS::CommandLineArgument do

  it "should split arguments" do
    ary = ['abc', 'def', '--', '123', '45', '6']
    a1, a2 = DRbQS::CommandLineArgument.split_arguments(ary)
    a1.should == ['abc', 'def']
    a2.should == ['123', '45', '6']
  end

  context "when checking size of array" do
    it "should return true" do
      ary = [1, 2, 3]
      DRbQS::CommandLineArgument.check_argument_size(ary, :>=, 1).should be_true
    end

    it "should return true" do
      ary = [1, 2, 3]
      DRbQS::CommandLineArgument.check_argument_size(ary, :>=, 1, :<=, 4).should be_true
    end

    it "should raise error" do
      ary = [1, 2, 3]
      lambda do
        DRbQS::CommandLineArgument.check_argument_size(ary, :==, 9)
      end.should raise_error
    end

    it "should raise error" do
      ary = [1, 2, 3]
      lambda do
        DRbQS::CommandLineArgument.check_argument_size(ary, :>, 0, :<=, 2)
      end.should raise_error
    end
  end
end
