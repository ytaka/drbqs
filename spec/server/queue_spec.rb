require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/server/queue'
require 'drbqs/task/task'

describe DRbQS::Server::Queue do
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
    @task = { :obj => DRbQS::Task.new([1, 2, 3], :size, []), :id => nil }
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

    it "should be empty." do
      subject.should be_empty
    end

    it "should be finished." do
      subject.should be_finished
    end
  end

  context "when adding a task" do
    before(:all) do
      object_init
      @task_id = subject.add(@task[:obj])
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

    it "should not be empty." do
      subject.empty?.should be_false
    end

    it "should not be finished." do
      subject.finished?.should be_false
    end

    it "should take objects from queue." do
      @ts[:queue].take([nil, nil, nil, nil]).should be_true
    end
  end

  context "when getting accept signal" do
    before(:all) do
      object_init
      @node_id = 100
      @task_id = subject.add(@task[:obj])
      @ts[:result].write([:accept, @task_id, 100])
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

    it "should be empty." do
      subject.should be_empty
    end

    it "should not be finished." do
      subject.should_not be_finished
    end

    it "should take objects from queue." do
      @ts[:result].read_all([nil, nil, nil]).size.should == 0
    end
  end

  context "when getting result" do
    before(:all) do
      object_init
      @node_id = 100
      @task_id = subject.add(@task[:obj])
      @ts[:result].write([:accept, @task_id, 100])
      subject.get_accept_signal
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

    it "should be empty." do
      subject.should be_empty
    end

    it "should not be finished." do
      subject.should be_finished
    end
  end

  context "when requeueing a task" do
    before(:all) do
      object_init
      @node_id = 100
      @task_id = subject.add(@task[:obj])
      @ts[:result].write([:accept, @task_id, 100])
      subject.get_accept_signal
      subject.requeue_for_deleted_node_id([@node_id])
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

    it "should be empty." do
      subject.should_not be_empty
    end

    it "should not be finished." do
      subject.should_not be_finished
    end

    it "should return task ID." do
      (ary = @ts[:queue].take([nil, nil, nil, nil])).should be_true
      ary[0].should == @task_id
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
      task_id = subject.add(@task[:obj])
      @task_id = subject.add(@task[:obj])
      @ts[:result].write([:accept, @task_id, 100])
      subject.get_accept_signal
      @ts[:result].write([:result, @task_id, @node_id, :result_object])
      subject.get_result(@server_dummy)
      @task[:obj].should_receive(:exec_hook)
      subject.exec_task_hook(@server_dummy, task_id, @result_dummy).should be_true
    end
  end

  context "when managing some tasks" do
    before(:all) do
      @task_ary = [DRbQS::Task.new([1, 2, 3], :size, []),
                   DRbQS::Task.new([1, 3], :size, []),
                   DRbQS::Task.new([2, 1, 2, 3], :size, [])]
      object_init
      @node_id = 100
      @task_id_ary = @task_ary.map do |task|
        subject.add(task)
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

    it "should be empty." do
      subject.should_not be_empty
    end

    it "should not be finished." do
      subject.should_not be_finished
    end
  end

end
