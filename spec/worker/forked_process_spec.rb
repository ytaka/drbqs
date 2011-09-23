# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/worker/worker'
require 'drbqs/task/task'

describe DRbQS::Worker::ForkedProcess do
  class CountExec
    @count = 0

    def self.add_count
      @count += 1
    end

    def self.get_count
      @count
    end

    def self.clear
      @count = 0
    end
  end

  def print_test_task(io_w, task_id)
    CountExec.clear
    ary = DRbQS::Task.new(CountExec, :add_count).simple_drb_args
    io_w.print DRbQS::Worker::Serialize.dump([task_id] + ary)
    io_w.print DRbQS::Worker::Serialize.dump(:prepare_to_exit)
    io_w.print DRbQS::Worker::Serialize.dump(:exit)
    io_w.flush
  end

  before(:each) do
    @io_r, @io_w = IO.pipe('BINARY')
    @io_r2, @io_w2 = IO.pipe('BINARY')
  end

  it "should do something" do
    task_id = 10
    print_test_task(@io_w, task_id)
    forked_process = DRbQS::Worker::SimpleForkedProcess.new(@io_r, @io_w2)
    forked_process.start
    CountExec.get_count.should == 1
    result = DRbQS::Worker::Serialize.load(@io_r2.readpartial(1024))
    result.should == [:result, [task_id, 1]]
  end

  it "should do something" do
    DRbQS::Temporary.should_receive(:set_sub_directory)
    task_id = 20
    print_test_task(@io_w, task_id)
    forked_process = DRbQS::Worker::ForkedProcess.new(@io_r, @io_w2)
    forked_process.start
    CountExec.get_count.should == 1
    result = DRbQS::Worker::Serialize.load(@io_r2.readpartial(1024))
    result[1][0].should == task_id
    result[1][1].should be_an_instance_of Hash
  end

  after(:each) do
    @io_r.close
    @io_w.close
    @io_r2.close
    @io_w2.close
  end
end
