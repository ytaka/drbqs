require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/server/message.rb'
require_relative '../integration_test/task_obj_definition.rb'

describe DRbQS::Manage do
  before(:all) do
    @uri = "druby://:13600"
    @ts = drbqs_test_tuple_space(@uri)
    @message = DRbQS::Server::Message.new(@ts[:message])
    @manage = DRbQS::Manage.new
  end

  it "should send exit signal" do
    lambda do
      @manage.send_exit_signal(@uri)
    end.should_not raise_error
    @message.get_message.should == [:exit_server]
  end

  it "should send node exit signal" do
    node_id = 100
    lambda do
      @manage.send_node_exit_after_task(@uri, node_id)
    end.should_not raise_error
    @message.get_message.should == [:exit_after_task, node_id]
  end

  it "should get status" do
    dummy_status = "status data"
    @ts[:message].write([:status, dummy_status])
    @manage.get_status(@uri).should == dummy_status
  end

  it "should execute over ssh" do
    command = "ls /"
    ssh_shell = mock
    DRbQS::Manage::SSHShell.stub(:new).and_return(ssh_shell)
    ssh_shell.should_receive(:start).with(command)
    @manage.execute_over_ssh("user@localhost", {}, command)
  end
end
