require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

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