require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/task/task'
require_relative 'definition/task_obj_definition.rb'

describe DRbQS do
  before(:all) do
    @tasks = [DRbQS::Task.new(Test3.new, :temp_file)]
    @process_id, @uri = drbqs_fork_server(13503, @tasks)
    @node = DRbQS::Node.new(@uri, :log_file => $stdout, :continue => true)
  end

  it "should initialize @task_client" do
    lambda do
      @node.connect
      @node.calculate
    end.should_not raise_error
  end

  after(:all) do
    lambda do
      drbqs_wait_kill_server(@process_id)
    end.should_not raise_error
  end

end
