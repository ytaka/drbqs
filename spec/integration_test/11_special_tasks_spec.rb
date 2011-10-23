require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/task/task'
require_relative 'definition/task_obj_definition.rb'

describe DRbQS do
  class TestValue
    @file = File.join(File.dirname(__FILE__), 'value.txt')

    def self.set(k, v)
      open(@file, 'a+') do |f|
        f.puts "#{k.to_s}\t#{v.to_s}"
      end
    end

    def self.get(val)
      if File.exist?(@file)
        File.read(@file).each_line do |l|
          if /^#{val.to_s}/ =~ l
            return l.split[1].to_i
          end
        end
      end
      nil
    end

    def self.clear
      FileUtils.rm(@file) if File.exist?(@file)
    end
  end

  before(:all) do
    @process_id, @uri = drbqs_fork_server(14110, :task => DRbQS::Task.new(Test1.new, :echo, args: [0])) do |server|
      server.set_initialization_task(DRbQS::Task.new(TestValue, :set, args: [:first, 1]),
                                     DRbQS::Task.new(TestValue, :set, args: [:second, 2]))
      server.set_finalization_task(DRbQS::Task.new(TestValue, :set, args: [:third, 3]),
                                   DRbQS::Task.new(TestValue, :set, args: [:fourth, 4]))
    end
    @node = DRbQS::Node.new(@uri, :log_file => $stdout)
  end

  it "should execute initialization tasks." do
    @node.connect
    TestValue.get(:first).should == 1
    TestValue.get(:second).should == 2
  end

  it "should execute finalization tasks" do
    @node.calculate
    sleep(1)                    # Wait finish of task.
    TestValue.get(:third).should == 3
    TestValue.get(:fourth).should == 4
  end

  after(:all) do
    TestValue.clear
    lambda do
      drbqs_wait_kill_server(@process_id, 30)
    end.should_not raise_error
  end
end
