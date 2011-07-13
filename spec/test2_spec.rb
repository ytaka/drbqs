require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'drbqs/task/task'
require_relative 'test/test1.rb'

describe DRbQS do
  before(:all) do
    @tasks = []
    @task_generators = [DRbQS::TaskGenerator.new(:iterate => 3), DRbQS::TaskGenerator.new(:iterate => 4)]
    @task_generators.each do |tg|
      tg.set do
        @iterate.times do |i|
          create_add_task(Test1.new, :echo, [i])
        end
      end
    end
    @process_id = fork do
      server = DRbQS::Server.new(:port => 13501, :finish_exit => true)
      @task_generators.each do |tg|
        server.add_task_generator(tg)
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
      drbqs_wait_kill_server(@process_id)
    end.should_not raise_error
  end

end
