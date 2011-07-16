require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/task/task'
require_relative 'task_obj_definition.rb'

describe DRbQS do
  before(:all) do
    @tasks = 3.times.map do |i|
      DRbQS::Task.new(Test1.new, :echo, [i])
    end
    @process_id, @uri = drbqs_fork_server(13501, @tasks)
    @manage = DRbQS::Manage.new(:uri => @uri)
  end

  it "should send exit signal" do
    lambda do
      @manage.send_exit_signal
    end.should_not raise_error
    lambda do
      drbqs_wait_kill_server(@process_id)
    end.should_not raise_error
  end
end
