require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/execute/process_define'

describe DRbQS::ProcessDefinition::Register do
  subject do
    DRbQS::ProcessDefinition::Register.new
  end

  context "when registering a server" do
    it "should define a server on localhost." do
      load_file = 'file.rb'
      subject.register_server(:server1) do |server|
        server.load load_file
      end
      name, data = subject.__server__.assoc(:server1)
      data[:type].should == :server
      data[:setting].get(:load).should == [load_file]
    end

    it "should define a server over ssh." do
      dest = "user@example.com"
      load_file = 'file.rb'
      subject.register_server(:server1) do |server, ssh|
        server.load load_file
        ssh.connect dest
      end
      name, data = subject.__server__.assoc(:server1)
      data[:type].should == :ssh
      setting = data[:setting]
      setting.get(:connect).should == [dest]
      setting.mode_setting.get(:load).should == [load_file]
    end
  end

  context "when registering a node" do
    it "should define a node on localhost." do
      uri = 'druby://:12345'
      subject.register_node(:node1) do |node|
        node.connect uri
      end
      name, data = subject.__node__.assoc(:node1)
      data[:type].should == :node
      data[:setting].get(:connect).should == [uri]
    end

    it "should define a node over ssh." do
      dest = "user@example.com"
      uri = 'druby://:12345'
      subject.register_node(:node2) do |node, ssh|
        node.connect uri
        ssh.connect dest
      end
      name, data = subject.__node__.assoc(:node2)
      data[:type].should == :ssh
      setting = data[:setting]
      setting.get(:connect).should == [dest]
      setting.mode_setting.get(:connect).should == [uri]
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
