require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/task/task'
require_relative 'definition/task_obj_definition.rb'

describe DRbQS do
  before(:all) do
    @tasks = 5.times.map do |i|
      DRbQS::Task.new(TestCount.new, :echo, args: [i])
    end
    @process_id, @uri = drbqs_fork_server(14010, :task => @tasks)
    @node = DRbQS::Node.new(@uri, :log_file => $stdout, :continue => true)
  end

  it "should have nil instance variables" do
    @node.instance_variable_get(:@task_client).should be_nil
    @node.instance_variable_get(:@connection).should be_nil
    @node.connect
  end

  it "should initialize @task_client" do
    task_node = @node.instance_variable_get(:@task_client)
    task_node.should be_an_instance_of DRbQS::Node::TaskClient
    task_node.node_number.should be_an_instance_of Fixnum
    task_node.task_empty?.should be_true
    task_node.result_empty?.should be_true
  end

  it "should initialize @connection" do
    connection = @node.instance_eval { @connection }
    connection.should be_an_instance_of DRbQS::Node::Connection
    connection.node_number.should be_an_instance_of Fixnum
    connection.id.should be_an_instance_of String
  end

  it "should calculate" do
    task_node = @node.instance_eval { @task_node }
    # *** Too late ***
    # task_node.should_receive(:add_new_task).at_least(:once)
    # task_node.should_receive(:transit).exactly(5).times
    # task_node.should_receive(:send_result).exactly(5).times
    lambda do
      @node.calculate
    end.should_not raise_error
    TestCount.get_execute_echo_number.should == @tasks.size
  end

  after(:all) do
    TestCount.clear
    lambda do
      drbqs_wait_kill_server(@process_id)
    end.should_not raise_error
  end

end
