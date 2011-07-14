require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/server/history'

describe DRbQS::History do

  def check_event(event, *vals)
    event[0].should be_an_instance_of Time
    event[1..-1].each_with_index do |obj, i|
      obj.should == vals[i]
    end
  end

  context "when setting events" do
    before(:all) do
      @history = DRbQS::History.new
      @history.set(1, :abc)
      @history.set(1, :def)
      @history.set(2, 'ABC', 'DEF')
      @history.set(3, :ghi)
      @history.set(1, :jkl)
      @history.set(2, 123, 456)
    end

    it "should have 3 items." do
      @history.should have(3).items
    end

    it "should 3 events of ID 1." do
      @history.number_of_events(1).should == 3
    end

    it "should 2 events of ID 2" do
      @history.number_of_events(2).should == 2
    end

    it "should 1 event of ID 3" do
      @history.number_of_events(3).should == 1
    end

    it "should check events of ID 1" do
      events = @history.events(1)
      check_event(events[0], :abc)
      check_event(events[1], :def)
      check_event(events[2], :jkl)
    end

    it "should check events of ID 2" do
      events = @history.events(2)
      check_event(events[0], 'ABC', 'DEF')
      check_event(events[1], 123, 456)
    end

    it "should check events of ID 1" do
      events = @history.events(3)
      check_event(events[0], :ghi)
    end

    it "should return strings of log" do
      @history.log_strings.should be_an_instance_of String
    end
  end

  context "when executing a method" do
    subject { DRbQS::History.new }

    it "should add new event" do
      id = 1
      subject.set(id, :connect)
      subject.should have(1).items
      subject.number_of_events(id).should == 1
      check_event(subject.events(1)[0], :connect)
    end

    it "should execute each events" do
      subject.set(3, '100', '200')
      subject.set(3, '300', '400')
      subject.set(4, 500, 600, 700)
      subject.each do |id, events|
        case id
        when 3
          check_event(events[0], '100', '200')
          check_event(events[1], '300', '400')
        when 4
          check_event(events[0], 500, 600, 700)
        end
      end
    end
  end
end
