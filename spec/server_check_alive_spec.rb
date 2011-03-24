require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'drbqs/server'

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
    check = DRbQS::CheckAlive.new(0.1)
    sleep(0.3)
    check.significant_interval?.should be_true
    check.set_checking
    sleep(0.01)
    check.significant_interval?.should be_false
  end

  it "should return false" do
    check = DRbQS::CheckAlive.new(100)
    check.significant_interval?.should be_false
  end
end
