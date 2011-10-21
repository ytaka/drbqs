require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DRbQS::Node::State do
  def make_all_processes_wait
    @process_number.times do |i|
      subject.change(i, :wait)
    end
  end

  before(:all) do
    @process_number = 3
  end

  subject do
    DRbQS::Node::State.new(:wait, @process_number)
  end

  context "when getting process number" do
    it "should yield each process number." do
      wids = []
      subject.each_worker_id do |wid|
        wids << wid
      end
      wids.sort.should == @process_number.times.to_a.sort
    end

    it "should get waiting process number." do
      subject.waiting_worker_id.sort.should ==  @process_number.times.to_a.sort
    end

    it "should get waiting process number with not waiting process." do
      waiting = []
      @process_number.times do |i|
        if i == 2
          subject.change(i, :calculate)
        else
          waiting << i
        end
      end
      subject.waiting_worker_id.sort.should == waiting
    end
  end

  context "when requesting new tasks" do
    before(:each) do
      make_all_processes_wait
    end

    it "should request." do
      subject.request?.should be_true
    end

    it "should request for all processes." do
      subject.request_task_number.should == @process_number
    end

    it "should request except for one process." do
      subject.change(0, :calculate)
      subject.request_task_number.should == @process_number - 1
    end
  end

  context "when state is :wait" do
    before(:each) do
      @process_number.times do |i|
        subject.change(i, :wait)
      end
    end

    it "should change to :sleep." do
      subject.change_to_sleep
      @process_number.times do |i|
        subject.get_state(i).should == :sleep
      end
    end

    it "should sleep." do
      subject.sleep_with_auto_wakeup
      @process_number.times do |i|
        subject.get_state(i).should == :sleep
      end
    end

    it "should wakeup." do
      subject.wakeup_sleeping_worker
      @process_number.times do |i|
        subject.get_state(i).should == :wait
      end
    end
  end

  context "when state is :sleep" do
    before(:each) do
      @process_number.times do |i|
        subject.change(i, :sleep)
      end
    end

    it "should change to :sleep." do
      subject.change_to_sleep
      @process_number.times do |i|
        subject.get_state(i).should == :sleep
      end
    end

    it "should sleep." do
      subject.sleep_with_auto_wakeup
      @process_number.times do |i|
        subject.get_state(i).should == :sleep
      end
    end

    it "should wakeup." do
      subject.wakeup_sleeping_worker
      @process_number.times do |i|
        subject.get_state(i).should == :wait
      end
    end
  end

  context "when state is :calculate" do
    before(:each) do
      @process_number.times do |i|
        subject.change(i, :calculate)
      end
    end

    it "should change to :sleep." do
      subject.change_to_sleep
      @process_number.times do |i|
        subject.get_state(i).should == :calculate
      end
    end

    it "should sleep." do
      subject.sleep_with_auto_wakeup
      @process_number.times do |i|
        subject.get_state(i).should == :calculate
      end
    end

    it "should wakeup." do
      subject.wakeup_sleeping_worker
      @process_number.times do |i|
        subject.get_state(i).should == :calculate
      end
    end
  end

  context "when state is :calculate" do
    before(:each) do
      @process_number.times do |i|
        subject.change(i, :exit)
      end
    end

    it "should change to :sleep." do
      subject.change_to_sleep
      @process_number.times do |i|
        subject.get_state(i).should == :exit
      end
    end

    it "should sleep." do
      subject.sleep_with_auto_wakeup
      @process_number.times do |i|
        subject.get_state(i).should == :exit
      end
    end

    it "should wakeup." do
      subject.wakeup_sleeping_worker
      @process_number.times do |i|
        subject.get_state(i).should == :exit
      end
    end
  end

  context "when getting load average." do
    it "should get load average." do
      File.stub(:read).with(DRbQS::Node::State::LOADAVG_PATH).and_return('0.00 0.01 0.05 1/404 5903')
      ary = subject.__send__(:get_load_average)
      ary.should be_an_instance_of Array
      ary.should have(3).items
      ary.all? do |num|
        Float === num
      end.should be_true
    end
  end

  context "when setting load average" do
    subject do
      DRbQS::Node::State.new(:wait, 1, :max_loadavg => 2)
    end

    it "should be true" do
      subject.stub(:get_load_average).and_return([2.0, 2,0, 2.0])
      subject.__send__(:system_busy?).should be_true
    end

    it "should be nil" do
      subject.stub(:get_load_average).and_return([1.0, 1,0, 1.0])
      subject.__send__(:system_busy?).should be_nil
    end
  end

  context "when setting auto wakeup" do
    before(:all) do
      @check_worker_id = 0
    end

    subject do
      DRbQS::Node::State.new(:wait, 1, :sleep_time => 0)
    end

    it "should do nothing." do
      make_all_processes_wait
      subject.stub(:system_busy?).and_return(nil)
      lambda do
        subject.wakeup_automatically_for_unbusy_system
      end.should_not change { subject.get_state(@check_worker_id) }
    end

    it "should do nothing." do
      subject.stub(:system_busy?).and_return(nil)
      subject.sleep_with_auto_wakeup
      lambda do
        subject.wakeup_automatically_for_unbusy_system
      end.should change { subject.get_state(@check_worker_id) }.from(:sleep).to(:wait)
    end
  end
end
