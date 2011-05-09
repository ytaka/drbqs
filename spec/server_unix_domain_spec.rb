require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require_relative '../lib/drbqs.rb'
require_relative 'test/test1.rb'

describe DRbQS::Server do
  before(:all) do
    @tasks = []
    5.times do |i|
      @tasks << DRbQS::Task.new(Test1.new, :echo, [i])
    end
    path = "/tmp/drbqs"
    @process_id = fork do
      server = DRbQS::Server.new(:unix => path)

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

    @uri = "drbunix:#{path}"
    @manage = DRbQS::Manage.new
  end

  it "should get status" do
    @manage.get_status(@uri).should be_true
  end

  it "should send exit signal" do
    lambda do
      @manage.send_exit_signal(@uri)
    end.should_not raise_error
  end

  after(:all) do
    lambda do
      drbqs_wait_kill_server(@process_id)
    end.should_not raise_error
  end

end
