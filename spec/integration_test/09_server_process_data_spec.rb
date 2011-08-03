require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/command_line/command_line'
require 'drbqs/task/task'
require 'drbqs/utility/temporary'

describe DRbQS::Server do
  def wait_file_creation(path)
    @max_wait_time.times do |i|
      if File.exist?(path)
        break
      end
      sleep(1)
    end
  end

  before(:all) do
    @file = DRbQS::Temporary.file
    @initial_data = ['abc', 'def']
    @max_wait_time = 10
    @server_process_id, @uri = drbqs_fork_server(14090, :opts => { :not_exit => true }) do |server|
      server.add_hook(:process_data) do |srv, data|
        open(@file, 'a+') do |f|
          f.print data
        end
      end
      server.set_data(*@initial_data)
    end
    @manage = DRbQS::Manage.new(:uri => @uri)
  end

  it "should process initial data." do
    wait_file_creation(@file)
    File.read(@file).should == 'abcdef'
  end

  it "should save to the file." do
    data = 'hello world'
    @manage.send_data(data)
    wait_file_creation(@file)
    File.read(@file).should == data
  end

  it "should send string by command." do
    data = 'send command'
    fork do
      DRbQS::Command::Manage.exec(['send', 'string', @uri, data])
    end
    wait_file_creation(@file)
    File.read(@file).should == data
  end

  it "should send file by command." do
    path = File.expand_path(__FILE__)
    fork do
      DRbQS::Command::Manage.exec(['send', 'file', @uri, path])
    end
    wait_file_creation(@file)
    File.read(@file).should == File.read(path)
  end

  after(:each) do
    FileUtils.rm(@file) if File.exist?(@file)
  end

  after(:all) do
    DRbQS::Temporary.delete_all
    @manage.send_exit_signal
    lambda do
      drbqs_wait_kill_server(@server_process_id)
    end.should_not raise_error
  end

end
