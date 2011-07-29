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
      info = @info[:server].sort_by { |a| a [0] }
      info.should == [[:server_local, :server], [:server_ssh, :ssh]].sort_by { |a| a [0] }
    end

    it "should get node list." do
      info = @info[:node].sort_by { |a| a[0] }
      info.should == [[:node_local, :node], [:node_ssh, :ssh]].sort_by { |a| a[0] }
    end

    it "should get default server." do
      @info[:default][:server].should == :server_local
    end

    it "should get default nodes." do
      info = @info[:default][:node].sort
      info.should == @info[:node].map { |a| a[0] }.sort
    end

    it "should get default port." do
      @info[:default][:port].should be_an_instance_of Fixnum
    end

    it "should get information as string." do
      subject.information_string.should be_an_instance_of String
    end

    it "should get usage." do
      subject.usage.should be_an_instance_of String
    end

    after(:all) do
      DRbQS.clear_definition
    end
  end

  context "when there is no definition" do
    subject do
      DRbQS::ProcessDefinition.new(nil, nil, nil)
    end

    before(:all) do
      subject.load(definition_file('no_def.rb'))
      @info = subject.information
    end

    it "should get server list." do
      @info[:server].should be_empty
    end

    it "should get node list." do
      @info[:node].should be_empty
    end

    it "should get default server." do
      @info[:default][:server].should be_nil
    end

    it "should get default nodes." do
      @info[:default][:node].should be_empty
    end

    it "should get default port." do
      @info[:default][:port].should be_an_instance_of Fixnum
    end

    it "should get information as string." do
      subject.information_string.should be_an_instance_of String
    end

    it "should get usage." do
      subject.usage.should be_an_instance_of String
    end

    after(:all) do
      DRbQS.clear_definition
    end
  end
end
