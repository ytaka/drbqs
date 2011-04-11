require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'drbqs/queue'

describe DRbQS::QueueServer do
  before(:all) do
    @ts = {
      :queue => Rinda::TupleSpace.new,
      :result => Rinda::TupleSpace.new
    }
    @queue_server = DRbQS::QueueServer.new(@ts[:queue], @ts[:result])
    @task = { :obj => DRbQS::Task.new([1, 2, 3], :size, []), :id => nil }
    @node_id = 100
  end

  it "should be empty" do
    @queue_server.calculating_task_number.should == 0
    @queue_server.empty?.should be_true
    @queue_server.finished?.should be_true
  end

  it "should add a task" do
    @task[:id] = @queue_server.add(@task[:obj])
    @queue_server.calculating_task_number.should == 0
    @queue_server.empty?.should be_false
    @queue_server.finished?.should be_false
    @ts[:queue].take([nil, nil, nil, nil]).should be_true
  end

  it "should get accept signal" do
    @ts[:result].write([:accept, @task[:id], @node_id])
    @queue_server.get_accept_signal.should == 1
    @queue_server.calculating_task_number.should == 1
    @queue_server.empty?.should be_true
    @queue_server.finished?.should be_false
    @ts[:result].read_all([nil, nil, nil]).size.should == 0
  end

  it "should get result" do
    @ts[:result].write([:result, @task[:id], @node_id, :result_object])
    @queue_server.get_result(nil) # The argument should be DRbQS::Server by right.
    @queue_server.calculating_task_number.should == 0
    @queue_server.empty?.should be_true
    @queue_server.finished?.should be_true
  end

  it "should delete node" do
    @task[:id] = @queue_server.add(@task[:obj])
    @ts[:queue].take([nil, nil, nil, nil]).should be_true
    @ts[:result].write([:accept, @task[:id], 100])
    @queue_server.get_accept_signal.should == 1
    @queue_server.requeue_for_deleted_node_id([@node_id])
    @queue_server.calculating_task_number.should == 0
    @queue_server.empty?.should be_false
    @queue_server.finished?.should be_false
    (ary = @ts[:queue].take([nil, nil, nil, nil])).should be_true
    ary[0].should == @task[:id]
  end
end
