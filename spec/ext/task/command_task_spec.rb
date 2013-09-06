require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe DRbQS::CommandTask::CommandExecute do
  it "should execute command" do
    cmd_exec = DRbQS::CommandTask::CommandExecute.new(['ls > /dev/null', "echo hello > /dev/null"])
    cmd_exec.exec.should == [0, 0]
  end

  it "should enqueue files" do
    DRbQS::Transfer.should_receive(:enqueue).exactly(2)
    cmd_exec = DRbQS::CommandTask::CommandExecute.new('ls > /dev/null', :transfer => ['hello', 'world'])
    cmd_exec.exec.should == [0]
  end
end
