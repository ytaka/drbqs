require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/node/task_client'

describe DRbQS::Node::TaskClient do
  def init_task_client(opts = {})
    @node_number = opts[:number] || 10
    @ts_queue = Rinda::TupleSpace.new
    @ts_result = Rinda::TupleSpace.new
    @task_client = DRbQS::Node::TaskClient.new(@node_number, @ts_queue, @ts_result, opts[:group])
  end

  def add_task_to_tuplespace(task_id, task_ary, group = DRbQS::Task::DEFAULT_GROUP)
    @ts_queue.write([group, task_id] + task_ary)
  end

  def check_empty_queue_tuplespace
    @ts_queue.read_all([nil, nil, nil, nil, nil]).size.should == 0
  end

  subject do
    @task_client
  end

  context "when we get initial task client" do
    before(:all) do
      init_task_client
    end

    it "should have empty task queue." do
      subject.task_empty?.should be_true
    end

    it "should have empty result queue." do
      subject.result_empty?.should be_true
    end

    it "should not have calculating task." do
      subject.calculating_task.should be_nil
    end

    it "should return no task." do
      subject.get_task.should be_nil
    end

    it "should not have group." do
      subject.group.should == []
    end
  end

  context "when getting task" do
    before(:all) do
      init_task_client
      @task_id = 3
      @task_ary = ["hello world", :size, []]
      add_task_to_tuplespace(@task_id, @task_ary)
    end

    it "should return task" do
      subject.get_task.should == @task_ary.dup.unshift(@task_id)
    end

    it "should take out task from tuplespace." do
      check_empty_queue_tuplespace
    end
  end

  context "when getting task by group" do
    before(:all) do
      init_task_client(:group => [:grp1])
      @task_id = 3
      @task_ary = ["hello world", :size, []]
      add_task_to_tuplespace(@task_id, @task_ary, :grp1)
    end

    it "should not return task." do
      client = DRbQS::Node::TaskClient.new(100, @ts_queue, @ts_result, nil)
      client.get_task.should be_nil
    end

    it "should return task." do
      subject.get_task.should == @task_ary.dup.unshift(@task_id)
    end

    it "should take out task from tuplespace." do
      check_empty_queue_tuplespace
    end

    it "should have group." do
      subject.group.should == [:grp1]
    end
  end

  context "when getting new task" do
    before(:all) do
      init_task_client(:number => 7)
    end

    it "should return nil" do
      subject.add_new_task.should be_nil
    end

    it "should return nil" do
      add_task_to_tuplespace(100, [[1, 3, 5, 7], :size, []])
      subject.add_new_task.should be_true
    end
  end

  context "when adding new task" do
    before(:all) do
      init_task_client(:number => 7)
      @task_id = 3
      @task_ary = [[1, 3, 5, 7], :size, []]
      add_task_to_tuplespace(@task_id, @task_ary)
      subject.add_new_task
    end

    it "should have non empty task queue." do
      subject.task_empty?.should_not be_true
    end

    it "should have empty result queue." do
      subject.result_empty?.should be_true
    end

    it "should have calculating task" do
      subject.calculating_task.should == @task_id
    end

    it "should take out task from tuplespace." do
      check_empty_queue_tuplespace
    end

    it "should get :accept signal." do
      @ts_result.take([:accept, nil, nil], 0).should == [:accept, @task_id, subject.node_number]
    end
  end

  context "when dequeueing a task" do
    before(:all) do
      init_task_client(:number => 14)
      @task_id = 8
      @task_ary = [[1, 3, 5, 7], :size, []]
      add_task_to_tuplespace(@task_id, @task_ary)
      subject.add_new_task
      @dequeued_task = subject.dequeue_task
    end

    it "should get a task" do
      @dequeued_task.should == @task_ary
    end

    it "should have empty task queue." do
      subject.task_empty?.should be_true      
    end

    it "should have empty result queue." do
      subject.result_empty?.should be_true      
    end

    it "should have calculating task." do
      subject.calculating_task.should == @task_id      
    end
  end

  context "when queueing result" do
    before(:all) do
      init_task_client(:number => 2)
      @task_id = 27
      @task_ary = ["abcdef", :size, []]
      add_task_to_tuplespace(@task_id, @task_ary)
      subject.add_new_task
      @dequeued_task = subject.dequeue_task
      subject.queue_result(:result_object)
    end

    it "should have empty task queue." do
      subject.task_empty?.should be_true      
    end

    it "should have non empty result queue." do
      subject.result_empty?.should_not be_true
    end

    it "should have calculating task." do
      subject.calculating_task.should == @task_id
    end
  end

  context "when sending result" do
    before(:all) do
      init_task_client(:number => 2)
      @task_id = 27
      @task_ary = ["abcdef", :size, []]
      add_task_to_tuplespace(@task_id, @task_ary)
      subject.add_new_task
      @dequeued_task = subject.dequeue_task
      subject.queue_result(:result_object)
      @send_returned_value = subject.send_result
    end

    it "should get nil returned value." do
      @send_returned_value.should be_nil
    end

    it "should have empty task queue." do
      subject.task_empty?.should be_true      
    end

    it "should have empty result queue." do
      subject.result_empty?.should_not be_nil
    end

    it "should not have calculating task." do
      subject.calculating_task.should be_nil
    end

    it "should get result from tuplespace." do
      @ts_result.take([:result, nil, nil, nil], 0).should be_true
    end
  end

  context "when setting exit_after_task" do
    before(:all) do
      init_task_client(:number => 2)
      @task_id = 27
      @task_ary = ["abcdef", :size, []]
      add_task_to_tuplespace(@task_id, @task_ary)
      subject.add_new_task
      subject.set_exit_after_task
      @dequeued_task = subject.dequeue_task
      subject.queue_result(:result_object)
    end

    it "should return true" do
      subject.send_result.should be_true
    end
  end

  context "when dumping result queue" do
    before(:all) do
      init_task_client(:number => 2)
    end

    it "should return nil for empty result queue." do
      subject.dump_result_queue.should be_nil
    end

    it "should return string for non empty result queue." do
      results = [:result_object1, :result_object2]
      results.each do |sym|
        subject.queue_result(sym)
      end
      subject.dump_result_queue.should == Marshal.dump(results)
    end
  end
end
