require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'drbqs/utility/command_line'

describe DRbQS::CommandBase do
  it "should define DRbQS::CommandBase.exec." do
    argv = [1, 2, 3]
    obj = mock
    DRbQS::CommandBase.should_receive(:new).and_return(obj)
    obj.should_receive(:parse_option)
    obj.should_receive(:exec)
    DRbQS::CommandBase.exec(argv)
  end

  subject do
    DRbQS::CommandBase.new
  end

  it "should exit with 0." do
    Kernel.should_receive(:exit).with(0)
    subject.__send__(:exit_normally)
  end

  it "should exit." do
    Kernel.should_receive(:exit)
    subject.__send__(:exit_unusually)
  end

  it "should exit." do
    Kernel.should_receive(:exit)
    subject.__send__(:exit_invalid_option)
  end
end