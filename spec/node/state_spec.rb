require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DRbQS::Node::State do
  subject do
    DRbQS::Node::State.new(:wait)
  end

  context "when state is :wait" do
    before(:each) do
      subject.change(:wait)
    end

    it "should change to :wait." do
      lambda do
        subject.change_to_wait
      end.should_not change { subject.state }
    end

    it "should change to :sleep." do
      lambda do
        subject.change_to_sleep
      end.should change { subject.state }.from(:wait).to(:sleep)
    end

    it "should change to :calculate." do
      lambda do
        subject.change_to_calculate
      end.should change { subject.state }.from(:wait).to(:calculate)
    end
  end

  context "when state is :sleep" do
    before(:each) do
      subject.change(:sleep)
    end

    it "should change to :sleep." do
      lambda do
        subject.change_to_wait
      end.should change { subject.state }.from(:sleep).to(:wait)
    end

    it "should change to :sleep." do
      lambda do
        subject.change_to_sleep
      end.should_not change { subject.state }
    end

    it "should change to :calculate." do
      lambda do
        subject.change_to_calculate
      end.should change { subject.state }.from(:sleep).to(:calculate)
    end
  end

  context "when state is :calculate" do
    before(:each) do
      subject.change(:calculate)
    end

    it "should change to :sleep." do
      lambda do
        subject.change_to_wait
      end.should_not change { subject.state }
    end

    it "should change to :sleep." do
      lambda do
        subject.change_to_sleep
      end.should_not change { subject.state }
    end

    it "should change to :calculate." do
      lambda do
        subject.change_to_calculate
      end.should_not change { subject.state }
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
      DRbQS::Node::State.new(:wait, :max_loadavg => 2)
    end

    it "should be true" do
      subject.stub(:get_load_average).and_return([2.0, 2,0, 2.0])
      subject.system_busy?.should be_true
    end

    it "should be nil" do
      subject.stub(:get_load_average).and_return([1.0, 1,0, 1.0])
      subject.system_busy?.should be_nil
    end
  end

  context "when changing state to finish calculating" do
    before(:each) do
      subject.change(:calculate)
    end

    it "should change to :wait." do
      lambda do
        subject.change_to_finish_calculating
      end.should change { subject.state }.from(:calculate).to(:wait)
    end

    it "should change to :sleep." do
      subject.change_to_sleep
      lambda do
        subject.change_to_finish_calculating
      end.should change { subject.state }.from(:calculate).to(:sleep)
    end
  end

  context "when setting auto wakeup" do
    subject do
      DRbQS::Node::State.new(:wait, :sleep_time => 0)
    end

    it "should do nothing." do
      subject.stub(:system_busy?).and_return(nil)
      subject.change(:wait)
      lambda do
        subject.wakeup_automatically_for_unbusy_system
      end.should_not change { subject.state }
    end

    it "should do nothing." do
      subject.stub(:system_busy?).and_return(nil)
      subject.sleep_with_auto_wakeup
      lambda do
        subject.wakeup_automatically_for_unbusy_system
      end.should change { subject.state }.from(:sleep).to(:wait)
    end
  end
end
