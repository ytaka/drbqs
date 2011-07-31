require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/task/task'

describe DRbQS::Task do
  it "should not set hook" do
    task = DRbQS::Task.new([1, 2, 3], :size)
    task.hook.should be_nil
  end

  it "should set hook" do
    task = DRbQS::Task.new([1, 2, 3], :size) do |server, ret|
      p ret
    end
    task.hook.should be_an_instance_of Proc
  end

  it "should have same targets" do
    task1 = DRbQS::Task.new([1, 2, 3], :concat, [3, 4, 5])
    task2 = DRbQS::Task.new([1, 2, 3], :concat, [3, 4, 5])
    task1.same_target?(task2).should be_true
  end
end

describe DRbQS::Task::TaskSet::Container do
  it "should dump and load" do
    obj = [[1], [1, 2], [1, 2, 3]]
    tasks = obj.map do |ary|
      DRbQS::Task.new(ary, :size)
    end
    container = DRbQS::Task::TaskSet::Container.new(tasks)
    dump = Marshal.dump(container)
    Marshal.load(dump).should == container
  end

  it "should execute each task" do
    obj = [[1, 3, 4], [2], [1, 2, 3]]
    tasks = obj.map do |ary|
      DRbQS::Task.new(ary, :size)
    end
    container = DRbQS::Task::TaskSet::Container.new(tasks)
    container.exec.should == [3, 1, 3]
  end
end

describe DRbQS::Task::TaskSet do
  it "should execute hooks" do
    server = double('server')
    methods_for_hook = double('hook')
    methods_for_hook.should_receive(:m0).exactly(1)
    methods_for_hook.should_receive(:m1).exactly(1)
    methods_for_hook.should_receive(:m2).exactly(1)
    obj = [[1], [1, 2], [1, 2, 3]]
    tasks = []
    tasks << DRbQS::Task.new(obj[0], :size, &methods_for_hook.method(:m0))
    tasks << DRbQS::Task.new(obj[1], :size, &methods_for_hook.method(:m1))
    tasks << DRbQS::Task.new(obj[2], :size, &methods_for_hook.method(:m2))
    task_set = DRbQS::Task::TaskSet.new(tasks)
    task_set.hook.call(server, [1, 2, 3])
  end
end
