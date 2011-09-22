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
  end

  it "should kill process." do
    key = :proc2
    send_task(key)
    pid = subject.process[key][:pid]
    subject.kill_process(key)
    sleep(0.1)
    Sys::ProcTable.ps(pid).should be_nil
  end

  it "should kill all processes." do
    [:proc3, :proc4].each do |key|
      send_task(key)
    end
    subject.kill_all_processes
    sleep(0.2)
    Process.waitall.should == []
  end

  it "should kill all processes compellingly." do
    [:proc5, :proc6].each do |key|
      send_task(key)
    end
    subject.kill_all_processes(true)
    subject.waitall
    Process.waitall.should == []
  end

  after(:all) do
    subject.kill_all_processes(true)
  end
end
