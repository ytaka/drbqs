require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/node/task_client'

describe DRbQS::TaskClient do
  before(:all) do
    @node_id = 4
    @ts_queue = Rinda::TupleSpace.new
    @ts_result = Rinda::TupleSpace.new
    @task_client = DRbQS::TaskClient.new(@node_id, @ts_queue, @ts_result)
    @task_example = [[1, 2, 3], :size, []]
    @task_id = 10
  end

  it "should be empty" do
    @task_client.task_empty?.should be_true
    @task_client.result_empty?.should be_true
    @task_client.calculating_task.should be_nil
  end

  it "should queue a task" do
    @ts_queue.write([@task_id] + @task_example)
    @task_client.add_new_task
    @task_client.task_empty?.should_not be_true
    @task_client.result_empty?.should be_true
    @task_client.calculating_task.should == @task_id
    @ts_queue.read_all([nil, nil, nil, nil]).size.should == 0
    @ts_result.take([:accept, nil, nil], 0).should be_true
  end

  it "should dequeue a task" do
    ary = @task_client.dequeue_task
    ary.should == @task_example
    @task_client.task_empty?.should be_true
    @task_client.result_empty?.should be_true
    @task_client.calculating_task.should == @task_id
  end

  it "should queue result" do
    @task_client.queue_result(@task_example[0].__send__(@task_example[1], *@task_example[2]))
    @task_client.task_empty?.should be_true
    @task_client.result_empty?.should_not be_true
    @task_client.calculating_task.should == @task_id
  end

  it "should send result" do
    @task_client.send_result.should be_nil
    @task_client.task_empty?.should be_true
    @task_client.result_empty?.should be_true
    @task_client.calculating_task.should be_nil
    @ts_result.take([:result, nil, nil, nil], 0).should be_true
  end

  it "should set exit_after_task" do
    @ts_queue.write([@task_id] + @task_example)
    @task_client.set_exit_after_task
    @task_client.add_new_task
    @task_client.task_empty?.should be_true
    @task_client.send_result.should be_true
  end
end
