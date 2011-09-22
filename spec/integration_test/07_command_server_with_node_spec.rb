require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/task/task'
require 'drbqs/command_line/command_line'

describe DRbQS do
  context "when server is executed with nodes." do
    it "should exit normally." do
      @path = File.expand_path(File.join(File.dirname(__FILE__), 'definition/server01.rb'))
      @port = 14070
      @pid_server = fork do
        DRbQS::Command::Server.exec([@path, '-p', @port.to_s, '--execute-node', '2'])
      end
      lambda do
        i = 0
        until exit_data = Process.waitpid2(@pid_server, Process::WNOHANG)
          sleep(1)
          if i > 10
            raise "Server can not stop within 10 seconds."
          end
        end
        exit_data[1].success?.should be_true
      end.should_not raise_error
    end

    it "should raise error in server." do
      puts "**** This test output errors to stdout ****"
      @path = File.expand_path(File.join(File.dirname(__FILE__), 'definition/server02.rb'))
      @port = 14071
      lambda do
        DRbQS::Command::Server.exec([@path, '-p', @port.to_s, '--execute-node', '2'])
      end.should raise_error
      # @pid_server = fork do
      #   DRbQS::Command::Server.exec([@path, '-p', @port.to_s, '--execute-node', '2'])
      # end
      # lambda do
      #   i = 0
      #   until exit_data = Process.waitpid2(@pid_server, Process::WNOHANG)
      #     sleep(1)
      #     if i > 10
      #       raise "Server can not stop within 10 seconds."
      #     end
      #   end
      #   exit_data[1].success?.should_not be_true
      # end.should_not raise_error
    end
  end
end
