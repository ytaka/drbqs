require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require_relative '../lib/drbqs.rb'
require_relative 'test/test1.rb'

describe DRbQS do
  before(:all) do
    @tasks = []
    @task_generator = DRbQS::TaskGenerator.new(:iterate => 3)
    @task_generator.set do
      @iterate.times do |i|
        create_add_task(Test1.new, :echo, [i])
      end
    end
    @process_id = fork do
      server = DRbQS::Server.new(:port => 13501)

      server.set_task_generator(@task_generator)

      server.set_finish_hook do |serv|
        serv.exit
      end

      server.set_signal_trap
      server.start
      server.wait
    end
    sleep(1)

    @uri = 'druby://:13501'
    @client = DRbQS::Client.new(@uri, :log_file => $stdout, :continue => true)
  end

  it "should have nil instance variables" do
    @client.instance_variable_get(:@task_client).should be_nil
    @client.instance_variable_get(:@connection).should be_nil
    @client.connect
  end

  it "should initialize @task_client" do
    task_client = @client.instance_variable_get(:@task_client)
    task_client.should be_an_instance_of DRbQS::TaskClient
    task_client.node_id.should be_an_instance_of Fixnum
    task_client.task_empty?.should be_true
    task_client.result_empty?.should be_true
  end

  it "should initialize @connection" do
    connection = @client.instance_eval { @connection }
    connection.should be_an_instance_of DRbQS::ConnectionClient
    connection.instance_variable_get(:@id_number).should be_an_instance_of Fixnum
    connection.instance_variable_get(:@id_string).should be_an_instance_of String
  end

  it "should calculate" do
    lambda do
      @client.calculate
    end.should_not raise_error
  end

  after(:all) do
    lambda do
      i = 0
      while !Process.waitpid(@process_id, Process::WNOHANG)
        i += 1
        if i > 10
          Process.kill(:KILL, @process_id)
          raise "Server process does not finish."
        end
        sleep(1)
      end
    end.should_not raise_error
  end

end
