require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/execute/process_define'

describe DRbQS::ProcessDefinition do
  def definition_file(name)
    File.join(File.dirname(__FILE__), 'def', name)
  end

  context "when creating without default process names" do
    subject do
      DRbQS::ProcessDefinition.new(nil, nil, nil)
    end

    before(:all) do
      subject.load(definition_file('execute1.rb'))
      @info = subject.information
    end

    it "should get server list." do
      @info[:server].sort.should == [:server_local, :server_ssh].sort
    end

    it "should get node list." do
      @info[:node].sort.should == [:node_local, :node_ssh].sort
    end

    it "should get default server." do
      @info[:default][:server].should == :server_local
    end

    it "should get default nodes." do
      @info[:default][:node].sort.should == @info[:node].sort
    end

    it "should get default port." do
      @info[:default][:port].should be_an_instance_of Fixnum
    end
  end
end
