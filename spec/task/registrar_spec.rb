require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/task/task'

describe DRbQS::Task::Registrar do
  subject do
    DRbQS::Task::Registrar.new({})
  end

  it "should raise error for invalid argumuents." do
    lambda do
      subject.add("neither DRbQS::Task nor Array")
    end.should raise_error ArgumentError
  end

  it "should call Fiber.yield." do
    task = DRbQS::Task.new([1, 2, 3], :size, nil, "calculate size of an array")
    Fiber.should_receive(:yield).with(task)
    subject.add(task)
  end

  it "should call Fiber.yield for each task." do
    task_ary = 5.times.map do |i|
      DRbQS::Task.new(i, :to_s, nil, "convert to string")
    end
    Fiber.should_receive(:yield).exactly(task_ary.size).times
    subject.add(task_ary)
  end

  it "should call Fiber.yield with :wait." do
    Fiber.should_receive(:yield).with(:wait)
    subject.wait
  end
end
