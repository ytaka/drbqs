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

  it "should return string for shell." do
    obj = DRbQS::Setting::Base.new(:all_keys_defined => true, :log_level => true, :daemon => true)
    obj.value.log_level 'debug'
    obj.value.daemon '/path/to/log'
    obj.parse!
    str = obj.string_for_shell
    str.should match(/--log-level/)
    str.should match(/--daemon/)
    str.should match(/debug/)
    str.should match(/\/path\/to\/log/)
  end

  it "should not change when executing parse! twice." do
    obj = DRbQS::Setting::Base.new(:all_keys_defined => true, :log_level => true, :daemon => true)
    obj.value.log_level 'debug'
    obj.value.daemon '/path/to/log'
    obj.parse!
    lambda do
      obj.parse!
    end.should_not change(obj, :string_for_shell)
  end

  it "should clone an object." do
    obj = DRbQS::Setting::Base.new(:all_keys_defined => true, :log_level => true, :daemon => true)
    obj.value.daemon '/path/to/log'
    obj.value.log_level 'debug'
    obj_clone = obj.clone
    obj.value.daemon << '/add'
    obj.value.daemon.should_not == obj_clone.value.daemon
    obj_clone.value.debug 'error'
    obj_clone.value.debug.should_not == obj.value.debug
  end
end
