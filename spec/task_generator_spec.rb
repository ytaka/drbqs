require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'drbqs/task_generator'

describe DRbQS::TaskGenerator do
  def check_task_ary(tasks, num)
    tasks.should have(num).items
    tasks.all? { |t| DRbQS::Task === t }.should be_true
  end

  subject { DRbQS::TaskGenerator.new(:abc => 'ABC', :def => 123, :data => [1, 2, 3]) }

  it "should initialize instance varibles" do
    source = subject.instance_variable_get('@source')
    source.instance_variable_get('@abc').should == 'ABC'
    source.instance_variable_get('@def').should == 123
  end

  it "should create new tasks" do
    subject.set(2) do
      @data.each do |i|
        create_add_task(i, :to_s)
      end
    end
    subject.init
    check_task_ary(subject.new_tasks, 2)
    check_task_ary(subject.new_tasks, 1)
    subject.new_tasks.should be_nil
  end

  it "should debug generator" do
    subject.set(2) do
      @data.each do |i|
        create_add_task(i, :to_s)
      end
    end
    subject.init
    group_number, task_number = subject.debug_all_tasks
    group_number.should == 2
    task_number.should == 3
  end

  it "should wait" do
    subject.set(2) do
      @data.each do |i|
        if i == 2
          wait_all_tasks
        end
        create_add_task(i, :to_s)
      end
    end
    subject.init
    subject.waiting?.should be_false
    check_task_ary(subject.new_tasks, 1)
    subject.waiting?.should be_true
    check_task_ary(subject.new_tasks, 2)
    subject.waiting?.should be_false
  end
end
