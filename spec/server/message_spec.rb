require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/server/message.rb'
require 'drbqs/task/task'

describe DRbQS::MessageServer do
  before(:all) do
    @message = Rinda::TupleSpace.new
    @message_server = DRbQS::MessageServer.new(@message)
    @node_id_list = []
  end

  it "should return nil" do
    @message_server.get_message.should be_nil
  end

  it "should have no node" do
    @message_server.node_not_exist?.should be_true
  end

  it "should set initialization task" do
    lambda do
      @message.take([:initialize, nil, Symbol, nil], 0)
    end.should raise_error Rinda::RequestExpiredError
    @message_server.set_initialization(DRbQS::Task.new(Object.new, :object_id))
    @message.take([:initialize, nil, Symbol, nil], 0).should be_true
  end

  it "should set finalization task" do
    lambda do
      @message.take([:finalization, nil, Symbol, nil], 0)
    end.should raise_error Rinda::RequestExpiredError
    @message_server.set_finalization(DRbQS::Task.new(Object.new, :object_id))
    @message.take([:finalization, nil, Symbol, nil], 0).should be_true
  end

  it "should get :connect message" do
    5.times do |i|
      id_str = "connect_test_#{i}"
      @message.write([:server, :connect, id_str])
      @message_server.get_message
      (ary = @message.take([id_str, Fixnum])).should be_true
      @node_id_list << ary[1]
      @message_server.node_not_exist?.should be_false
    end
  end

  it "should get :alive message" do
    node_id = 73
    @message.write([:server, :alive, node_id])
    node_list = @message_server.instance_variable_get(:@node_list)
    node_list.should_receive(:set_alive).with(node_id)
    @message_server.get_message
  end

  it "should get :exit_server message" do
    @message.write([:server, :exit_server, 'message_test'])
    @message_server.get_message.should == [:exit_server]
  end

  it "should get :exit_after_task message" do
    @message.write([:server, :exit_after_task, 1])
    @message_server.get_message.should == [:exit_after_task, 1]
  end

  it "should send exit message" do
    @message_server.send_exit
    @node_id_list.each do |id|
      @message.take([id, :exit]).should be_true
    end
  end

  it "should send exit_after_task message" do
    id = 1
    @message_server.send_exit_after_task(id)
    @message.take([id, :exit_after_task]).should be_true
  end

  it "should delete a node" do
    @message_server.check_connection.should == []
    @node_id_list.each do |id|
      @message.take([id, :alive_p]).should be_true
    end
    @message_server.check_connection.should == @node_id_list
    @node_id_list.each do |id|
      lambda do
        @message.take([id, :alive_p], 0)
      end.should raise_error Rinda::RequestExpiredError
    end
  end

  it "should get :request_status message" do
    @message.write([:server, :request_status, 'message_test'])
    @message_server.get_message.should == [:request_status]
  end

  it "should send status" do
    @message_server.send_status({})
    @message.take([:status, nil]).should be_true
  end
end
