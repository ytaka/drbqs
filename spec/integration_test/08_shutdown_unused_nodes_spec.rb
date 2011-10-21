require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/task/task'
require 'drbqs/command_line/command_line'

describe DRbQS::Server do
  before(:all) do
    @max_wait_time = 10
    @server_process_id, @uri = drbqs_fork_server(14080, :opts => { :shutdown_unused_nodes => true, :not_exit => true })
    @manage = DRbQS::Manage.new(:uri => @uri)
  end

  it "should send node exit" do
    execute_node = DRbQS::Execution::ExecuteNode.new(@uri, nil, nil)
    client_process_id = fork do
      execute_node.execute(1)
    end
    th = Process.detach(client_process_id)
    lambda do
      @max_wait_time.times do |i|
        sleep(1)
        unless th.alive?
          break
        end
        if i == (@max_wait_time - 1)
          raise "Client does not exit."
        end
      end
    end.should_not raise_error
  end

  after(:all) do
    @manage.send_exit_signal
    lambda do
      drbqs_wait_kill_server(@server_process_id)
    end.should_not raise_error
  end

end
