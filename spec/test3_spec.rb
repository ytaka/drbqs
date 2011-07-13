require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'drbqs/task/task'
require_relative 'test/test1.rb'

describe DRbQS do
  before(:all) do
    @tasks = [DRbQS::Task.new(Test3.new, :temp_file)]
    @process_id = fork do
      server = DRbQS::Server.new(:port => 13503)

      @tasks.each do |task|
        server.queue.add(task)
      end

      server.add_hook(:finish) do |serv|
        serv.exit
      end

      server.set_signal_trap
      server.start
      server.wait
    end
    sleep(1)

    @uri = 'druby://:13503'
    @client = DRbQS::Client.new(@uri, :log_file => $stdout, :continue => true)
  end

  it "should initialize @task_client" do
    lambda do
      @client.connect
      @client.calculate
    end.should_not raise_error
  end

  after(:all) do
    lambda do
      drbqs_wait_kill_server(@process_id)
    end.should_not raise_error
  end

end
