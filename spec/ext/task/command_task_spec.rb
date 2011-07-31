require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'drbqs/ext/task'

describe DRbQS::CommandTask::CommandExecute do
  it "should execute command" do
    cmd_exec = DRbQS::CommandTask::CommandExecute.new('ls > /dev/null')
    cmd_exec.exec.should == 0
  end

  it "should enqueue files" do
    DRbQS::Transfer.should_receive(:enqueue).exactly(2)
    cmd_exec = DRbQS::CommandTask::CommandExecute.new('ls > /dev/null', :transfer => ['hello', 'world'])
    cmd_exec.exec
  end
end
