require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs'
require_relative 'task_obj_definition.rb'

describe DRbQS::Server do
  before(:all) do
    @tasks = 2.times.map do |i|
      DRbQS::Task.new(Test1.new, :echo, [i])
    end
    path = "/tmp/drbqs"
    @process_id, @uri = drbqs_fork_server(path, @tasks)
    @manage = DRbQS::Manage.new
    @client = DRbQS::Client.new(@uri, :log_file => $stdout, :continue => true)
  end

  it "should send signal and get status" do
    @manage.get_status(@uri).should be_true
  end

  it "should calculate task" do
    @client.connect
    lambda do
      @client.calculate
    end.should_not raise_error
  end

  after(:all) do
    lambda do
      drbqs_wait_kill_server(@process_id)
    end.should_not raise_error
  end

end
