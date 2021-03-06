require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/task/task'
require_relative 'definition/task_obj_definition.rb'

describe DRbQS do
  before(:all) do
    @task_generators = [DRbQS::Task::Generator.new(:iterate => 3), DRbQS::Task::Generator.new(:iterate => 4)]
    @task_generators.each do |tg|
      tg.set do
        @iterate.times do |i|
          create_add(Test1.new, :echo, args: [i])
        end
      end
    end
    @process_id, @uri = drbqs_fork_server(14020, :task => @task_generators)
    @node = DRbQS::Node.new(@uri, :log_file => $stdout)
  end

  it "should have nil instance variables" do
    @node.instance_variable_get(:@task_client).should be_nil
    @node.instance_variable_get(:@connection).should be_nil
    @node.connect
  end

  it "should initialize @task_client" do
    task_client = @node.instance_variable_get(:@task_client)
    task_client.should be_an_instance_of DRbQS::Node::TaskClient
    task_client.node_number.should be_an_instance_of Fixnum
    task_client.task_empty?.should be_true
    task_client.result_empty?.should be_true
  end

  it "should initialize @connection" do
    connection = @node.instance_eval { @connection }
    connection.should be_an_instance_of DRbQS::Node::Connection
    connection.node_number.should be_an_instance_of Fixnum
    connection.id.should be_an_instance_of String
  end

  it "should calculate" do
    lambda do
      @node.calculate
    end.should_not raise_error
  end

  after(:all) do
    lambda do
      drbqs_wait_kill_server(@process_id)
    end.should_not raise_error
  end

end
