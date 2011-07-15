require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/node/connection.rb'

describe DRbQS::Node::Connection do
  before(:all) do
    @message = Rinda::TupleSpace.new
    @connection = DRbQS::Node::Connection.new(@message)
    @node_id = 23
    id_string = @connection.instance_variable_get(:@id_string)
    @message.write([id_string, @node_id])
  end

  it "should get node ID." do
    @connection.get_id.should == @node_id
    @message.take([:server, :connect, nil], 0).should be_true
  end

  it "should get no initialization method." do
    @connection.get_initialization.should be_nil
  end

  it "should get initialization" do
    ary = [:initialize, [1, 2], :size, []]
    @message.write(ary)
    @connection.get_initialization.should == ary[1..-1]
  end

  it "should get no finalization method." do
    @connection.get_finalization.should be_nil
  end

  it "should get finalization" do
    ary = [:finalize, [1, 2], :size, []]
    @message.write(ary)
    @connection.get_finalization.should == ary[1..-1]
  end

  it "should respond :alive_p signal" do
    @message.write([@node_id, :alive_p])
    @connection.respond_signal
    @message.take([:server, :alive, nil], 0).should be_true
  end

  it "should respond :exit signal" do
    @message.write([@node_id, :exit])
    @connection.respond_signal.should == :exit
  end
end