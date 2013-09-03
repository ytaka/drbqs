require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/server/queue'
require 'drbqs/task/task'

describe DRbQS::Server::Queue do
  QUEUE_OBJECT_PATTERN = [nil, nil, nil, nil, nil]

  def object_init
    @ts = {
      :queue => Rinda::TupleSpace.new,
      :result => Rinda::TupleSpace.new
    }
    @queue_server = DRbQS::Server::Queue.new(@ts[:queue], @ts[:result])
    @server_dummy = nil
  end

  subject do
    @queue_server
  end

  before(:all) do
    @task = { :obj => DRbQS::Task.new([1, 2, 3], :size), :id => nil }
  end

  context "when initializing queue" do
    before(:all) do
      object_init
    end

    it "should return number of acceptances of signals." do
      subject.get_accept_signal.should == 0
    end

    it "should return number of acceptances of resultss." do
      subject.get_result(@server_dummy).should == 0
    end

    it "should have no calculating task." do
      subject.calculating_task_number.should == 0
    end

    it "should get number of stocked tasks." do
      subject.stocked_task_number.should == 0
    end

    it "should be empty." do
      subject.should be_empty
    end

    it "should be finished." do
      subject.should be_finished
    end

    it "should return an array of calculating nodes." do
      subject.calculating_nodes.should == []
    end
  end

  context "when adding a task" do
    before(:all) do
      object_init
      @task_id = @queue_server.add(@task[:obj])
    end

    it "should return number of acceptances of signals." do
      subject.get_accept_signal.should == 0
    end

    it "should return number of acceptances of resultss." do
      subject.get_result(@server_dummy).should == 0
    end

    it "should have no calculating task." do
      subject.calculating_task_number.should == 0
    end

    it "should get number of stocked tasks." do
      subject.stocked_task_number.should == 1
    end

    it "should not be empty." do
      subject.empty?.should be_false
    end

    it "should not be finished." do
      subject.finished?.should be_false
    end

    it "should take objects from queue." do
      @ts[:queue].take(QUEUE_OBJECT_PATTERN).should be_true
    end

    it "should return an array of calculating nodes." do
      subject.calculating_nodes.should == []
    end
  end

  context "when getting accept signal" do
    before(:all) do
      object_init
      @node_id = 100
      @task_id = @queue_server.add(@task[:obj])
      @ts[:result].write([:accept, @task_id, @node_id])
    end

    it "should return number of acceptances of signals." do
      subject.get_accept_signal.should == 1
    end

    it "should return number of acceptances of resultss." do
      subject.get_result(@server_dummy).should == 0
    end

    it "should return number of calculating task." do
      subject.calculating_task_number.should == 1
    end

    it "should get number of stocked tasks." do
      subject.stocked_task_number.should == 0
    end

    it "should be empty." do
      subject.should be_empty
    end

    it "should not be finished." do
      subject.should_not be_finished
    end

    it "should take objects from queue." do
      @ts[:result].read_all([nil, nil, nil]).size.should == 0
    end

    it "should return an array of calculating nodes." do
      subject.calculating_nodes.should == [@node_id]
    end
  end

  context "when getting result" do
    before(:all) do
      object_init
      @node_id = 100
      @task_id = @queue_server.add(@task[:obj])
      @ts[:result].write([:accept, @task_id, @node_id])
      @queue_server.get_accept_signal
      @ts[:result].write([:result, @task_id, @node_id, :result_object])
    end

    it "should return number of acceptances of signals." do
      subject.get_accept_signal.should == 0
    end

    it "should return number of acceptances of resultss." do
      subject.get_result(@server_dummy).should == 1
    end

    it "should return number of calculating task." do
      subject.calculating_task_number.should == 0
    end

    it "should get number of stocked tasks." do
      subject.stocked_task_number.should == 0
    end

    it "should be empty." do
      subject.should be_empty
    end

    it "should not be finished." do
      subject.should be_finished
    end

    it "should return an array of calculating nodes." do
      subject.calculating_nodes.should == []
    end
  end

  context "when requeueing a task" do
    before(:all) do
      object_init
      @node_id = 100
      @task_id = @queue_server.add(@task[:obj])
      @ts[:result].write([:accept, @task_id, @node_id])
      @queue_server.get_accept_signal
      @queue_server.requeue_for_deleted_node_id([@node_id])
    end

    it "should return number of acceptances of signals." do
      subject.get_accept_signal.should == 0
    end

    it "should return number of acceptances of resultss." do
      subject.get_result(@server_dummy).should == 0
    end

    it "should return number of calculating task." do
      subject.calculating_task_number.should == 0
    end

    it "should get number of stocked tasks." do
      subject.stocked_task_number.should == 1
    end

    it "should be empty." do
      subject.should_not be_empty
    end

    it "should not be finished." do
      subject.should_not be_finished
    end

    it "should return task group and task ID." do
      (ary = @ts[:queue].take(QUEUE_OBJECT_PATTERN)).should be_true
      ary[0].should == DRbQS::Task::DEFAULT_GROUP
      ary[1].should == @task_id
    end

    it "should return an array of calculating nodes." do
      subject.calculating_nodes.should == []
    end
  end

  context "when some nodes are calculating" do
    before(:all) do
      object_init
      @node_ids = [200, 300]
      @tasks = [DRbQS::Task.new([1, 2, 3], :size),
                DRbQS::Task.new([-1, -2], :size),
                DRbQS::Task.new([8, 9, 10, 11], :size)]
      @task_ids = @tasks.map do |t|
        @queue_server.add(t)
      end
      @ts[:result].write([:accept, @task_ids[0], @node_ids[0]])
      @ts[:result].write([:accept, @task_ids[1], @node_ids[1]])
      @queue_server.get_accept_signal
    end

    it "should return number of acceptances of signals." do
      subject.get_accept_signal.should == 0
    end

    it "should return number of acceptances of resultss." do
      subject.get_result(@server_dummy).should == 0
    end

    it "should return number of calculating task." do
      subject.calculating_task_number.should == 2
    end

    it "should get number of stocked tasks." do
      subject.stocked_task_number.should == 1
    end

    it "should be empty." do
      subject.should_not be_empty
    end

    it "should not be finished." do
      subject.should_not be_finished
    end

    it "should return an array of calculating nodes." do
      subject.calculating_nodes.should == @node_ids.sort
    end
  end

  context "when executing hook of task" do
    before(:all) do
      object_init
      @result_dummy = nil
    end

    it "should do nothing" do
      subject.exec_task_hook(@server_dummy, 1, @result_dummy).should be_false
    end

    it "should execute hook of task" do
      @node_id = 100
      task_id = subject.add(@task[:obj])
      @task_id = subject.add(@task[:obj])
      @ts[:result].write([:accept, @task_id, @node_id])
      subject.get_accept_signal
      @ts[:result].write([:result, @task_id, @node_id, :result_object])
      subject.get_result(@server_dummy)
      @task[:obj].should_receive(:exec_hook)
      subject.exec_task_hook(@server_dummy, task_id, @result_dummy).should be_true
    end
  end

  context "when managing some tasks" do
    before(:all) do
      @task_ary = [DRbQS::Task.new([1, 2, 3], :size, note: 'task1'),
                   DRbQS::Task.new([1, 3], :size, note: 'task2'),
                   DRbQS::Task.new([2, 1, 2, 3], :size, note: 'task3')]
      object_init
      @node_id = 100
      @task_id_ary = @task_ary.map do |task|
        @queue_server.add(task)
      end
      @ts[:result].write([:accept, @task_id_ary[0], 100])
      @ts[:result].write([:accept, @task_id_ary[1], 101])
      @ts[:result].write([:result, @task_id_ary[0], @node_id, :result_object])
    end

    it "should return number of acceptances of signals." do
      subject.get_accept_signal.should == 2
    end

    it "should return number of acceptances of resultss." do
      subject.get_result(@server_dummy).should == 1
    end

    it "should return number of calculating task." do
      subject.calculating_task_number.should == 1
    end

    it "should get number of stocked tasks." do
      subject.stocked_task_number.should == 1
    end

    it "should be empty." do
      subject.should_not be_empty
    end

    it "should not be finished." do
      subject.should_not be_finished
    end
  end

  context "when creating messages of calculating tasks" do
    before(:all) do
      @task_ary = [DRbQS::Task.new([1, 2, 3], :size, note: 'task1'),
                   DRbQS::Task.new([1, 3], :size, note: 'task2'),
                   DRbQS::Task.new([2, 1, 2, 3], :size, note: 'task3')]
      object_init
      @node_id = 100
      @task_id_ary = @task_ary.map do |task|
        @queue_server.add(task)
      end
      @ts[:result].write([:accept, @task_id_ary[0], 100])
      @ts[:result].write([:accept, @task_id_ary[1], 101])
      @ts[:result].write([:result, @task_id_ary[0], @node_id, :result_object])
    end

    it "should return number of acceptances of signals." do
      subject.get_accept_signal.should == 2
    end
    
    it "should return calculating task messages." do
      messages = subject.calculating_task_message
      messages.should have(2).items
      messages[100].should == [[@task_id_ary[0], 'task1']]
      messages[101].should == [[@task_id_ary[1], 'task2']]
    end
  end

end
