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
  end

  subject do
    @worker
  end

  def file_path(key)
    File.join(File.dirname(__FILE__), "test_worker", "#{key}.txt")
  end

  def send_task(key, group = nil)
    path = file_path(key)
    FileUtils.mkdir(File.dirname(path)) unless File.exist?(File.dirname(path))
    task = DRbQS::Task.new(SavePID.new, :output, args: [path], group: group) do |wk, res|
      puts "Hook: receive #{res}"
    end
    subject.add_task(task)
  end

  it "should execute a task." do
    task_key = :task
    send_task(task_key)
    loop do
      subject.step
      unless @result.empty?
        break
      end
      sleep(0.1)
    end
    File.read(file_path(task_key)).lines.to_a[-1].strip.to_i.should == @result[0][1][1]
  end

  it "should execute a task on process of particular group." do
    pid = subject.process.process[:proc3][:pid]
    task_keys = [:task2, :task3]
    task_keys.each do |key|
      send_task(key, :gr3)
    end
    loop do
      subject.step
      if @result.size == 2
        break
      end
      sleep(0.1)
    end
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
    loop do
      subject.step
      if @result.size == 2
        break
      end
      sleep(0.1)
    end
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
    loop do
      subject.step
      if @result.size == 2
        break
      end
      sleep(0.1)
    end
    task_keys.each do |key|
      File.read(file_path(key)).lines.to_a[-1].strip.to_i.should == pid
    end
    subject.wakeup(:proc1, :proc3)
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
