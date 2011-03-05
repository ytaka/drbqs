require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'drbqs/connection.rb'

describe DRbQS::ConnectionClient do
  before(:all) do
    @message = Rinda::TupleSpace.new
    @connection = DRbQS::ConnectionClient.new(@message)
    @node_id = 23
    id_string = @connection.instance_variable_get(:@id_string)
    @message.write([id_string, @node_id])
  end

  it "should get node ID." do
    @connection.get_id.should == @node_id
    @message.take([:connect, nil]).should be_true
  end

  it "should get no initialization method." do
    @connection.get_initialization.should be_nil
  end

  it "should get initialization" do
    ary = [:initialize, [1, 2], :size, []]
    @message.write(ary)
    @connection.get_initialization.should == ary[1..-1]
  end

  it "should respond :alive_p signal" do
    @message.write([@node_id, :alive_p])
    @connection.respond_alive_signal
    @message.take([:alive, nil]).should be_true
  end

  it "should respond :exit signal" do
    @message.write([@node_id, :exit])
    @connection.respond_alive_signal.should == :exit
  end
end
