require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs'
require_relative 'definition/task_obj_definition.rb'

describe DRbQS::Server do
  before(:all) do
    @tasks = 2.times.map do |i|
      DRbQS::Task.new(Test1.new, :echo, args: [i])
    end
    path = "/tmp/drbqs"
    @process_id, @uri = drbqs_fork_server(path, :task => @tasks)
    @manage = DRbQS::Manage.new(:uri => @uri)
    @node = DRbQS::Node.new(@uri, :log_file => $stdout)
  end

  it "should send signal and get status" do
    @manage.get_status.should be_true
  end

  it "should calculate task" do
    @node.connect
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
