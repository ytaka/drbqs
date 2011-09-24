# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/worker'

describe DRbQS::Worker do
  class SavePID
    def output(path)
      pid = Process.pid
      open(path, 'a+') do |f|
        f.puts pid
      end
      pid
    end
  end

  before(:all) do
    @worker = DRbQS::Worker.new
    @error = []
    @result = []
    @worker.on_error do |proc_key, error|
      @error << [proc_key, error]
    end
    @worker.on_result do |proc_key, result|
      @result << [proc_key, result]
    end
    @worker.process.create_process(:proc1, :proc2, :proc3)
    @worker.group(:gr1, :proc1)
    @worker.group(:gr3, :proc3)
    @n = 0
    @interval_time = 0.1
  end

  subject do
    @worker
  end

  def file_path(key)
    File.join(File.dirname(__FILE__), "test_worker", "#{key}.txt")
  end

  def send_task(key, group = nil, broadcast = nil)
    path = file_path(key)
    FileUtils.mkdir(File.dirname(path)) unless File.exist?(File.dirname(path))
    task = DRbQS::Task.new(SavePID.new, :output, args: [path], group: group) do |wk, res|
      puts "Hook: receive #{res}"
    end
    subject.add_task(task, broadcast)
  end

  it "should execute a task." do
    task_key = :task
    task_id = send_task(task_key)
    subject.wait(task_id, @interval_time)
    File.read(file_path(task_key)).lines.to_a[-1].strip.to_i.should == @result[0][1][1]
  end

  it "should execute a task on process of particular group." do
    pid = subject.process.process[:proc3][:pid]
    task_keys = [:task2, :task3]
    task_keys.each do |key|
      send_task(key, :gr3)
    end
    subject.waitall(@interval_time)
    task_keys.each do |key|
      File.read(file_path(key)).lines.to_a[-1].strip.to_i.should == pid
    end
  end

  it "should sleep nodes." do
    subject.sleep(:proc1, :proc2)
    pid = subject.process.process[:proc3][:pid]
    task_keys = [:task4, :task5]
    task_keys.each do |key|
      send_task(key)
    end
    subject.waitall(@interval_time)
    task_keys.each do |key|
      File.read(file_path(key)).lines.to_a[-1].strip.to_i.should == pid
    end
    subject.wakeup(:proc1, :proc2)
  end

  it "should wakeup a node." do
    subject.sleep(:proc1, :proc2, :proc3)
    subject.wakeup(:proc2)
    pid = subject.process.process[:proc2][:pid]
    task_keys = [:task6, :task7]
    task_keys.each do |key|
      send_task(key)
    end
    subject.waitall(@interval_time)
    task_keys.each do |key|
      File.read(file_path(key)).lines.to_a[-1].strip.to_i.should == pid
    end
    subject.wakeup(:proc1, :proc3)
  end

  it "should send to all processes." do
    ary_pid = subject.process.all_processes.map do |proc_key|
      subject.process.process[proc_key][:pid]
    end
    key = :all
    send_task(key, nil, true)
    sleep(1)
    result_pid = File.read(file_path(key)).lines.map(&:to_i).sort
    result_pid.should == ary_pid.sort
  end

  it "should finish." do
    subject.process.create_process(:proc4, :proc5)
    subject.finish
    Process.waitall.should == []
  end

  after(:each) do
    @result.clear
    @error.clear
  end

  after(:all) do
    subject.process.kill_all_processes
    subject.process.waitall
    path = File.join(File.dirname(__FILE__), "test_worker")
    FileUtils.rm_r(path) if File.exist?(path)
  end
end
