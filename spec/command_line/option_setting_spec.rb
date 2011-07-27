require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/command_line/command_line'

describe DRbQS::Command::OptionSetting do
  subject do
    DRbQS::Command::OptionSetting.new('help message', DRbQS::Setting::Base.new)
  end

  it "should set log_level option." do
    subject.define(:log_level => true)
    subject.parse!(['--log-level', 'debug']).should be_empty
    subject.setting.get(:log_level).should == ['debug']
  end

  it "should set daemon option." do
    subject.define(:daemon => true)
    subject.parse!(['--daemon', '/path/to/log', 'other options']).should == ['other options']
    subject.setting.get(:daemon).should == ['/path/to/log']
  end

  it "should set an arbitrary option." do
    subject.define do
      set(:new_opt, '--new-opt NUM', Integer, 'Set the number.')
    end
    subject.parse!(['--new-opt', '123', 'HELLO']).should == ['HELLO']
    subject.setting.get(:new_opt).should == [123]
  end
end
