require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/task/task'
require_relative 'definition/task_obj_definition.rb'

describe DRbQS do
  before(:all) do
    @dir = 'test_pid_dir'
    FileUtils.mkdir(@dir) unless File.exist?(@dir)
    @number_of_task = 10
    @tasks = @number_of_task.times.map do |i|
      DRbQS::Task.new(TestPID.new, :save, args: [@dir])
    end
    @process_number = 3
    @process_id, @uri = drbqs_fork_server(14120, :task => @tasks)
    @node = DRbQS::Node.new(@uri, :log_file => $stdout, :process => @process_number)
  end

  it "should calculate" do
    @node.connect
    lambda do
      @node.calculate
    end.should_not raise_error
    paths = Dir.glob(File.join(@dir, '*')).select do |file|
      /^\d+$/ =~ File.basename(file)
    end
    paths.uniq.should have(@process_number).items
    n = 0
    paths.each do |path|
      n += File.read(path).to_i
    end
    n.should == @number_of_task
  end

  after(:all) do
    TestCount.clear
    lambda do
      drbqs_wait_kill_server(@process_id)
    end.should_not raise_error
    FileUtils.rm_r(@dir) if File.exist?(@dir)
  end

end
