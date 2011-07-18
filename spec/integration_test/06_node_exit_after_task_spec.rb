require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/manage/execute_node'
require_relative 'definition/task_obj_definition.rb'

describe DRbQS::Server do
  before(:all) do
    @wait = 2
    @tasks = 10.times.map do |i|
      DRbQS::Task.new(Test2.new, :echo_wait, [@wait])
    end
    @server_process_id, @uri = drbqs_fork_server(13501, @tasks, :continue => true)
    @manage = DRbQS::Manage.new(:uri => @uri)
  end

  it "should send node exit" do
    execute_node = DRbQS::ExecuteNode.new(@uri, nil, nil)
    execute_node.execute(1)
    client_process_id = execute_node.pid[0]
    sleep(@wait)
    @manage.send_node_exit_after_task(1)
    th = Process.detach(client_process_id)
    max_wait_time = @wait * 3
    max_wait_time.times do |i|
      sleep(1)
      unless th.alive?
        break
      end
      if i == (max_wait_time - 1)
        raise "Client does not exit."
      end
    end
  end

  after(:all) do
    @manage.send_exit_signal
    lambda do
      drbqs_wait_kill_server(@server_process_id)
    end.should_not raise_error
  end

end
