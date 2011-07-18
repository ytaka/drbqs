require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/manage/manage'

describe DRbQS::Manage::SendSignal do
  before(:all) do
    @ts = Rinda::TupleSpace.new
    @send_signal = DRbQS::Manage::SendSignal.new(@ts)
  end

  subject do
    @send_signal
  end

  it "should get ID of sender." do
    subject.sender_id.should be_an_instance_of String
  end

  it "should send :exit_signal." do
    @send_signal.send_exit_signal
    lambda do
      @ts.take([:server, :exit_server, @send_signal.sender_id], 0)
    end.should_not raise_error
  end

  it "should send :exit_after_task." do
    node_id = 100
    @send_signal.send_node_exit_after_task(node_id)
    lambda do
      @ts.take([:server, :exit_after_task, node_id], 0)
    end.should_not raise_error
  end

  it "should send signal to get status." do
    mes = 'message'
    @ts.should_receive(:take).once.and_return([:status, mes])
    @send_signal.get_status.should == mes
  end
end