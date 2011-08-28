require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/node/connection.rb'

describe DRbQS::Node::Connection do
  before(:all) do
    @message = Rinda::TupleSpace.new
    @connection = DRbQS::Node::Connection.new(@message)
    @node_id = 23
    @message.write([@connection.id, @node_id])
  end

  it "should get node ID." do
    @connection.node_number.should == @node_id
    @message.take([:server, :connect, nil], 0).should be_true
  end

  it "should get no initialization method." do
    @connection.get_initialization.should be_nil
  end

  it "should get initialization." do
    ary = DRbQS::Task.new([1, 2], :size).simple_drb_args
    @message.write([:initialize, ary])
    @connection.get_initialization.should == ary
  end

  it "should get no finalization method." do
    @connection.get_finalization.should be_nil
  end

  it "should get finalization." do
    ary = DRbQS::Task.new([1, 2], :size).simple_drb_args
    @message.write([:finalize, ary])
    @connection.get_finalization.should == ary
  end

  it "should raise error for invalid signal." do
    @message.write([@node_id, :alive_p])
    @connection.respond_signal
    @message.take([:server, :alive, nil], 0).should be_true
  end

  it "should respond :alive_p signal" do
    @message.write([@node_id, :invalid])
    lambda do
      @connection.respond_signal
    end.should raise_error
  end

  [:exit, :finalize, :exit_after_task].each do |sym|
    it "should respond #{sym} signal" do
      @message.write([@node_id, sym])
      @connection.respond_signal.should == sym
    end
  end

  it "should send node error message." do
    err_mes = "Node Error"
    @connection.send_node_error(err_mes)
    ary = @message.take([:server, :node_error, Array])
    ary[2][0].should == @node_id
    ary[2][1].should == err_mes
  end

end
