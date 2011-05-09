require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require_relative 'test/test1.rb'

describe DRbQS do
  before(:all) do
    @tasks = []
    5.times do |i|
      @tasks << DRbQS::Task.new(Test1.new, :echo, [i])
    end
    @process_id = fork do
      server = DRbQS::Server.new(:port => 13501)

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

    @uri = 'druby://:13501'

    @manage = DRbQS::Manage.new
  end

  it "should send exit signal" do
    lambda do
      @manage.send_exit_signal(@uri)
    end.should_not raise_error
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
