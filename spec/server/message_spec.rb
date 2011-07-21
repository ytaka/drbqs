require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/server/message.rb'
require 'drbqs/task/task'

describe DRbQS::Server::Message do
  before(:all) do
    @message = Rinda::TupleSpace.new
    @message_server = DRbQS::Server::Message.new(@message)
    @node_list = @message_server.instance_variable_get(:@node_list)
  end

  def set_nodes(num)
    num.times do |i|
      id_str = "connect_test_#{i}"
      @message.write([:server, :connect, id_str])
      @message_server.get_message.should == [:connect]
      id_str_reply, id_num = @message.take([id_str, nil])
    end
  end

  def clear_all_node
    @message_server.get_all_nodes.each do |id_num, id_str|
      @node_list.delete(id_num, :disconnect)
    end
  end

  context "when getting messages" do
    it "should return nil" do
      @message_server.get_message.should be_nil
    end

    it "should get :connect message" do
      5.times do |i|
        id_str = "connect_test_#{i}"
        @message.write([:server, :connect, id_str])
        @message_server.get_message.should == [:connect]
        id_str_reply, id_num = @message.take([id_str, nil])
        id_num.should > 0
      end
    end

    it "should get :alive message" do
      node_id = 73
      @message.write([:server, :alive, node_id])
      @node_list.should_receive(:set_alive).with(node_id)
      @message_server.get_message.should == [:alive]
    end

    it "should get :exit_server message" do
      @message.write([:server, :exit_server, 'message_test'])
      @message_server.get_message.should == [:exit_server]
    end

    it "should get :exit_after_task message" do
      @message.write([:server, :exit_after_task, 1])
      @message_server.get_message.should == [:exit_after_task, 1]
    end

    it "should get :request_status message" do
      @message.write([:server, :request_status, 'message_test'])
      @message_server.get_message.should == [:request_status]
    end

    it "should get :node_error message" do
      node_id = 74
      @message.write([:server, :node_error, [node_id, 'Error occurs.']])
      @node_list.should_receive(:delete).with(node_id, :error)
      @message_server.get_message.should == [:node_error, node_id]
    end

    it "should return nil for invalid message" do
      @message.write([:server, :invalid_message])
      @message_server.get_message.should be_nil
    end

    after(:all) do
      clear_all_node
    end
  end

  context "when sending messages" do
    before(:all) do
      set_nodes(5)
    end

    it "should send exit message" do
      @message_server.send_exit
      @message_server.get_all_nodes.each do |id_num, id_str|
        @message.take([id_num, :exit]).should be_true
      end
    end

    it "should send finalization message" do
      @message_server.send_finalization
      @message_server.get_all_nodes.each do |id_num, id_str|
        @message.take([id_num, :finalize]).should be_true
      end
    end

    it "should send exit_after_task message" do
      id = @message_server.get_all_nodes.to_a[0][0]
      @message_server.send_exit_after_task(id)
      @message.take([id, :exit_after_task]).should be_true
    end

    it "should send status" do
      @message_server.send_status({})
      sym, status = @message.take([:status, nil])
      status.should be_an_instance_of String
    end

    after(:all) do
      clear_all_node
    end
  end

  context "when setting special tasks" do
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
  end

  context "when checking existence of nodes" do
    before(:all) do
      clear_all_node
    end

    it "should return a hash" do
      @message_server.get_all_nodes.should be_an_instance_of Hash
    end

    it "should have no node" do
      @message_server.node_not_exist?.should be_true
    end

    it "should return nil" do
      # Minus ID is invalid. So the node of the ID does not exist.
      @message_server.node_exist?(-100).should_not be_true
    end

    it "should return true" do
      id_str = "checking_node"
      @message.write([:server, :connect, id_str])
      @message_server.get_message.should == [:connect]
      id_str_reply, id_num = @message.take([id_str, nil])
      @message_server.node_exist?(id_num).should be_true
    end

    after(:all) do
      clear_all_node
    end
  end

  context "when checking connection" do
    before(:all) do
      set_nodes(5)
    end

    it "should send :alive_p message" do
      @message_server.check_connection.should == []
      @message_server.get_all_nodes.each do |id_num, id_str|
        @message.take([id_num, :alive_p]).should be_true
      end
    end

    it "should delete nodes" do
      node_id_list = @message_server.get_all_nodes.to_a.map do |ary|
        ary[0]
      end.sort
      @message_server.check_connection.sort.should == node_id_list
      node_id_list.each do |id_num|
        lambda do
          @message.take([id_num, :alive_p], 0)
        end.should raise_error Rinda::RequestExpiredError
      end
    end

    after(:all) do
      clear_all_node
    end
  end
end
