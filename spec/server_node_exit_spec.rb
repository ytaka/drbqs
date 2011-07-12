require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require_relative '../lib/drbqs.rb'
require_relative '../lib/drbqs/manage/execute_node'
require_relative 'test/test1.rb'

describe DRbQS::Server do
  before(:all) do
    @tasks = []
    @wait = 2
    5.times do |i|
      @tasks << DRbQS::Task.new(Test2.new, :echo_wait, [@wait])
    end
    @port = 13501
    @server_process_id = fork do
      server = DRbQS::Server.new(:port => @port)

      @tasks.each do |task|
        server.queue.add(task)
      end

      server.set_signal_trap
      server.start
      server.wait
    end
    sleep(1)
    
    @manage = DRbQS::Manage.new
    @uri = "druby://localhost:#{@port}"
  end

  it "should send node exit" do
    execute_node = DRbQS::ExecuteNode.new(@uri, nil, nil)
    execute_node.execute(1)
    client_process_id = execute_node.pid[0]
    @manage.send_node_exit_after_task(@uri, 1)
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
    @manage.send_exit_signal(@uri)
    lambda do
      drbqs_wait_kill_server(@server_process_id)
    end.should_not raise_error
  end

end
