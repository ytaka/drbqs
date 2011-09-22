# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/worker/worker'
require 'drbqs/task/task'
require 'sys/proctable'

describe DRbQS::Worker do
  before(:all) do
    @worker = DRbQS::Worker.new
    @task_args = DRbQS::Task.new("hello world", :to_s).simple_drb_args
    @n = 0
  end

  subject do
    @worker
  end

  def send_task(key)
    subject.send_task(key, [(@n += 1)] + @task_args)
  end

  it "should create new process." do
    key = :proc1
    send_task(key)
    pid = subject.process[key][:pid]
    Sys::ProcTable.ps(pid).should be_true
    get_result_key = nil
    loop do
      subject.respond_signal do |k, res|
        get_result_key = k
      end
      if get_result_key
        break
      end
      sleep(0.1)
    end
    get_result_key.should == key
  end

  it "should make process exit." do
    key = :proc2
    send_task(key)
    pid = subject.process[key][:pid]
    subject.prepare_to_exit(key)
    loop do
      subject.respond_signal do |k, res|
      end
      unless subject.process[key]
        sleep(0.1)
        break
      end
      sleep(0.1)
    end
    Sys::ProcTable.ps(pid).should be_nil
  end

  it "should make all process exit." do
    [:proc3, :proc4].each do |key|
      send_task(key)
    end
    subject.prepare_to_exit
    loop do
      subject.respond_signal do |k, res|
      end
      if subject.process.empty?
        sleep(0.1)
        break
      end
      sleep(0.1)
    end
    Process.waitall.should == []
  end

  it "should kill all processes compellingly." do
    [:proc5, :proc6].each do |key|
      send_task(key)
    end
    subject.kill_all_processes
    subject.waitall
    Process.waitall.should == []
  end

  after(:all) do
    subject.kill_all_processes
    subject.waitall
  end
end
