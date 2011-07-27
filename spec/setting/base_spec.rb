require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DRbQS::Setting::Base do
  it "should get default registered options." do
    obj = DRbQS::Setting::Base.new
    obj.source.registered_keys.sort.should == [:debug].sort
  end

  it "should register built-in options." do
    obj = DRbQS::Setting::Base.new(:all_keys_defined => true, :log_level => true, :daemon => true)
    obj.source.registered_keys.sort.should == [:debug, :log_level, :daemon].sort
  end
end
