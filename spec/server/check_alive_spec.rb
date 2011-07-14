require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/server/check_alive'

describe DRbQS::CheckAlive do
  it "should raise error with not a number" do
    lambda do
      DRbQS::CheckAlive.new('abc')
    end.should raise_error
  end

  it "should raise error with a minus number" do
    lambda do
      DRbQS::CheckAlive.new(-10)
    end.should raise_error    
  end

  it "should return true" do
    check = DRbQS::CheckAlive.new(0.01)
    sleep(0.03)
    check.significant_interval?.should be_true
  end

  it "should return false" do
    check = DRbQS::CheckAlive.new(100)
    check.significant_interval?.should be_false
  end

  it "should set checking" do
    check = DRbQS::CheckAlive.new(0.1)
    sleep(0.2)
    check.set_checking
    check.significant_interval?.should be_false
  end
end
