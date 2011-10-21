# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/worker'
require 'drbqs/task/task'
require 'sys/proctable'

describe DRbQS::Worker::ProcessSet do
  [DRbQS::Worker::SimpleForkedProcess,
   DRbQS::Worker::ForkedProcess].each do |klass|
    context "when creating process #{klass.to_s}" do
      before(:all) do
        @worker = DRbQS::Worker::ProcessSet.new(klass)
        @task_args = DRbQS::Task.new("hello world", :to_s).simple_drb_args
        @error = []
        @result = []
        @worker.on_error do |proc_key, error|
          @error << [proc_key, error]
        end
        @worker.on_result do |proc_key, result|
          @result << [proc_key, result]
        end
        @n = 0
      end

      subject do
        @worker
      end

      def send_task(key)
        subject.send_task(key, [(@n += 1)] + @task_args)
      end

      it "should create new process." do
        subject.create_process(:proc0)
        subject.exist?(:proc0).should be_true
        subject.waiting?(:proc0).should be_true
        subject.calculating?(:proc0).should be_false
        subject.waiting_processes.should == [:proc0]
      end

      it "should create new process automatically and execute a task." do
        key = :proc1
        send_task(key)
        pid = subject.process[key][:pid]
        Sys::ProcTable.ps(pid).should be_true
        loop do
          subject.respond_signal
          unless @result.empty?
            break
          end
          sleep(0.1)
        end
        @result.should have(1).item
        @result[0][0].should == key
      end

      # Sometimes this spec fails. Later we investigate. (2011-10-21)
      it "should make process exit." do
        key = :proc2
        send_task(key)
        pid = subject.process[key][:pid]
        subject.prepare_to_exit(key)
        loop do
          subject.respond_signal
          sleep(0.1)
          unless subject.exist?(key)
            break
          end
        end
        Sys::ProcTable.ps(pid).should be_nil
      end

      it "should make all process exit." do
        [:proc3, :proc4].each do |key|
          send_task(key)
        end
        subject.prepare_to_exit
        subject.waitall
        Process.waitall.should == []
      end

      it "should kill all processes compellingly." do
        subject.create_process(:proc5, :proc6)
        [:proc7, :proc8].each do |key|
          send_task(key)
        end
        subject.kill_all_processes
        subject.waitall
        Process.waitall.should == []
      end

      after(:each) do
        @result.clear
        @error.clear
      end

      after(:all) do
        subject.kill_all_processes
        subject.waitall
      end
    end
  end
end
