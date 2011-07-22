require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/task/task'
require 'drbqs/utility/command_line'

describe DRbQS::Server do
  before(:all) do
    @max_wait_time = 10
    @server_process_id, @uri = drbqs_fork_server(13501, :continue => true, :opts => { :shutdown_unused_nodes => true })
    @manage = DRbQS::Manage.new(:uri => @uri)
  end

  it "should send node exit" do
    execute_node = DRbQS::ExecuteNode.new(@uri, nil, nil)
    execute_node.execute(1)
    client_process_id = execute_node.pid[0]
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
