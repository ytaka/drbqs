require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/task/task'

class TestTask
  def initialize(result)
    @result = result
  end

  def calc
  end

  def test_hook(srv, result)
    @result.should == result
  end
end

describe DRbQS::Task do
  it "should not set hook." do
    task = DRbQS::Task.new([1, 2, 3], :size)
    task.hook.should be_nil
  end

  it "should set hook of block." do
    task = DRbQS::Task.new([1, 2, 3], :size) do |server, ret|
      p ret
    end
    task.hook.should be_an_instance_of Proc
  end

  it "should set hook of symbol." do
    task = DRbQS::Task.new([1, 2, 3], :size, hook: :to_s)
    task.hook.should == :to_s
  end

  it "should return nil for nonexistent hook." do
    task = DRbQS::Task.new([1, 2, 3], :size)
    task.exec_hook(nil, nil).should be_nil
  end

  it "should execute hook of block." do
    mock = mock('for task')
    task = DRbQS::Task.new(mock, :calc) do |server, result|
      mock.hook_method(server, result)
    end
    mock.should_receive(:hook_method).with(:server, :result)
    task.exec_hook(:server, :result)
  end

  it "should execute hook of symbol." do
    mock = mock('for task')
    task = DRbQS::Task.new(mock, :calc, hook: :hook_method)
    mock.should_receive(:hook_method).with(:server, :result)
    task.exec_hook(:server, :result)
  end

  it "should set note." do
    note_string = "Return size"
    task = DRbQS::Task.new([1, 2, 3], :size, note: note_string)
    task.note.should == note_string
  end

  it "should not have note." do
    note_string = "Return size"
    task = DRbQS::Task.new([1, 2, 3], :size)
    task.note.should be_nil
  end

  it "should have empty argument array." do
    task = DRbQS::Task.new([1, 2, 3], :size)
    task.args.should == []
  end

  it "should set arguments." do
    ary = [3, 4, 5]
    task = DRbQS::Task.new([1, 2, 3], :concat, args: ary)
    task.args.should == ary
  end

  it "should marshalize." do
    task = DRbQS::Task.new(TestTask.new(100), :calc, hook: :test_hook)
    lambda do
      Marshal.dump(task)
    end.should_not raise_error
  end

  it "should not marshalize." do
    task = DRbQS::Task.new(TestTask.new(100), :calc) do |srv, res|
      p res
    end
    lambda do
      Marshal.dump(task)
    end.should raise_error
  end
end

describe DRbQS::Task::TaskSet::ContainerTask do
  it "should dump and load" do
    obj = [[1], [1, 2], [1, 2, 3]]
    tasks = obj.map do |ary|
      DRbQS::Task.new(ary, :size)
    end
    container = DRbQS::Task::TaskSet::ContainerTask.new(tasks)
    dump = Marshal.dump(container)
    Marshal.load(dump).should == container
  end

  it "should execute each task" do
    obj = [[1, 3, 4], [2], [1, 2, 3]]
    tasks = obj.map do |ary|
      DRbQS::Task.new(ary, :size)
    end
    container = DRbQS::Task::TaskSet::ContainerTask.new(tasks)
    container.exec.should == [3, 1, 3]
  end
end

describe DRbQS::Task::TaskSet::ContainerWithoutHook do
  it "should dump and load" do
    obj = [[1], [1, 2], [1, 2, 3]]
    tasks = obj.map do |ary|
      DRbQS::Task.new(ary, :size)
    end
    container = DRbQS::Task::TaskSet::ContainerWithoutHook.new(tasks)
    dump = Marshal.dump(container)
    Marshal.load(dump).should == container
  end

  it "should execute each task" do
    obj = [[1, 3, 4], [2], [1, 2, 3]]
    tasks = obj.map do |ary|
      DRbQS::Task.new(ary, :size)
    end
    container = DRbQS::Task::TaskSet::ContainerWithoutHook.new(tasks)
    container.exec.should == [3, 1, 3]
  end
end

describe DRbQS::Task::TaskSet do
  it "should use DRbQS::Task::TaskSet::ContainerTask." do
    tasks = [DRbQS::Task.new([1, 2], :to_s), DRbQS::Task.new([1, 2], :size, hook: :to_s)]
    task_set = DRbQS::Task::TaskSet.new(tasks)
    task_set.obj.should be_an_instance_of DRbQS::Task::TaskSet::ContainerTask
  end

  it "should use DRbQS::Task::TaskSet::ContainerWithoutHook." do
    tasks = []
    tasks << DRbQS::Task.new([1, 2], :to_s) do |srv, result|
      p result
    end
    tasks << DRbQS::Task.new([1, 2], :size) do |srv, result|
      p result
    end
    task_set = DRbQS::Task::TaskSet.new(tasks)
    task_set.obj.should be_an_instance_of DRbQS::Task::TaskSet::ContainerWithoutHook
  end

  it "should execute hooks of blocks." do
    server = mock('server')
    methods_for_hook = mock('hook')
    methods_for_hook.should_receive(:m0).exactly(1)
    methods_for_hook.should_receive(:m1).exactly(1)
    methods_for_hook.should_receive(:m2).exactly(1)
    obj = [[1], [1, 2], [1, 2, 3]]
    tasks = []
    tasks << DRbQS::Task.new(obj[0], :size, &methods_for_hook.method(:m0))
    tasks << DRbQS::Task.new(obj[1], :size, &methods_for_hook.method(:m1))
    tasks << DRbQS::Task.new(obj[2], :size, &methods_for_hook.method(:m2))
    task_set = DRbQS::Task::TaskSet.new(tasks)
    task_set.exec_hook(server, [1, 2, 3])
  end

  it "should execute hooks of symbols." do
    server = mock('server')
    obj = [TestTask.new(100), TestTask.new(200), TestTask.new(300)]
    tasks = []
    tasks << DRbQS::Task.new(obj[0], :some_method, hook: :test_hook)
    tasks << DRbQS::Task.new(obj[1], :some_method, hook: :test_hook)
    tasks << DRbQS::Task.new(obj[2], :some_method, hook: :test_hook)
    task_set = DRbQS::Task::TaskSet.new(tasks)
    task_set.exec_hook(server, [100, 200, 300])
  end
end
