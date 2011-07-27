require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/execute/process_define'

describe DRbQS::ProcessDefinition::Register do
  subject do
    DRbQS::ProcessDefinition::Register.new
  end

  context "when registering a server" do
    
  end

  context "when registering a node" do
    it "should define node on localhost." do
      subject.register_node(:node1) do |node|
        node.connect 'abc'
      end
      p subject.__node__
    end
  end

  context "when setting default" do
    it "should set default server and default port." do
      subject.default(:server => :server1, :port => 1234)
      h = subject.__default__
      h[:server].should == :server1
      h[:port].should == 1234
    end

    it "should set default server and default port with conversion." do
      subject.default(:server => 'server2', :port => '12345')
      h = subject.__default__
      h[:server].should == :server2
      h[:port].should == 12345
    end
  end
end
