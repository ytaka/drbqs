require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/server/message.rb'
require_relative '../test/test1.rb'

describe DRbQS::Manage do
  before(:all) do
    @uri = "druby://:13600"
    @ts = drbqs_test_tuple_space(@uri)
    @message = DRbQS::MessageServer.new(@ts[:message])
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
end
