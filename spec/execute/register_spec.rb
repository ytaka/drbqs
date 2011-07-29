require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/execute/process_define'

describe DRbQS::ProcessDefinition::Register do
  subject do
    DRbQS::ProcessDefinition::Register.new
  end

  context "when registering a server" do
    it "should define a server on localhost." do
      load_file = 'file.rb'
      subject.register_server(:server1, "example.com") do |server|
        server.load load_file
      end
      name, data = subject.__server__.assoc(:server1)
      data[:type].should == :server
      data[:ssh].should be_false
      data[:template].should be_false
      setting = data[:setting]
      setting.get(:load).should == [load_file]
      setting.should be_an_instance_of DRbQS::Setting::Server
    end

    it "should define a server over ssh." do
      dest = "user@example.com"
      load_file = 'file.rb'
      subject.register_server(:server2, "example.com") do |server, ssh|
        server.load load_file
        ssh.connect dest
      end
      name, data = subject.__server__.assoc(:server2)
      data[:type].should == :server
      data[:ssh].should be_true
      data[:template].should be_false
      setting = data[:setting]
      setting.should be_an_instance_of DRbQS::Setting::SSH
      setting.get(:connect).should == [dest]
      setting.mode_setting.get(:load).should == [load_file]
    end

    it "should raise error for arguments without hostname." do
      load_file = 'file.rb'
      lambda do
        subject.register_server(:server3) do |server|
          server.load load_file
        end
      end.should raise_error
    end

    it "should set template." do
      load_file = 'file.rb'
      subject.register_server(:server4, :template => true) do |server|
        server.load load_file
      end
      name, data = subject.__server__.assoc(:server4)
      data[:template].should be_true
      data[:ssh].should be_false
      data[:type].should == :server
      setting = data[:setting]
      setting.get(:load).should == [load_file]
      setting.should be_an_instance_of DRbQS::Setting::Server
    end

    it "should define a server over ssh." do
      load_file = 'file.rb'
      bash = "bash"
      subject.register_server(:server5, :template => true) do |server, ssh|
        server.load load_file
        ssh.shell bash
      end
      name, data = subject.__server__.assoc(:server5)
      data[:type].should == :server
      data[:ssh].should be_true
      data[:template].should be_true
      setting = data[:setting]
      setting.should be_an_instance_of DRbQS::Setting::SSH
      setting.get(:shell).should == [bash]
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
      data[:ssh].should be_false
      data[:template].should be_false
      setting = data[:setting]
      setting.should be_an_instance_of DRbQS::Setting::Node
      setting.get(:connect).should == [uri]
    end

    it "should define a node over ssh." do
      dest = "user@example.com"
      uri = 'druby://:12345'
      subject.register_node(:node2) do |node, ssh|
        node.connect uri
        ssh.connect dest
      end
      name, data = subject.__node__.assoc(:node2)
      data[:type].should == :node
      data[:ssh].should be_true
      data[:template].should be_false
      setting = data[:setting]
      setting.should be_an_instance_of DRbQS::Setting::SSH
      setting.get(:connect).should == [dest]
      setting.mode_setting.get(:connect).should == [uri]
    end

    it "should define a node template." do
      uri = 'druby://:12345'
      subject.register_node(:node3, :template => true) do |node|
        node.connect uri
      end
      name, data = subject.__node__.assoc(:node3)
      data[:type].should == :node
      data[:ssh].should be_false
      data[:template].should be_true
      setting = data[:setting]
      setting.should be_an_instance_of DRbQS::Setting::Node
      setting.get(:connect).should == [uri]
    end

    it "should define a node over ssh." do
      dest = "user@example.com"
      uri = 'druby://:12345'
      subject.register_node(:node4, :template => true) do |node, ssh|
        node.connect uri
        ssh.connect dest
      end
      name, data = subject.__node__.assoc(:node4)
      data[:type].should == :node
      data[:ssh].should be_true
      data[:template].should be_true
      setting = data[:setting]
      setting.should be_an_instance_of DRbQS::Setting::SSH
      setting.get(:connect).should == [dest]
      setting.mode_setting.get(:connect).should == [uri]
    end

    it "should set node group." do
      nodes = [:node1, :node2]
      subject.register_node(:node_group, :group => nodes)
      name, data = subject.__node__.assoc(:node_group)
      data[:type].should == :group
      data[:template].should be_true
      data[:ssh].should_not be_true
      data[:args].should == nodes
    end

    it "should raise error for invalid node group." do
      lambda do
        subject.register_node(:node_group, :group => :node_error)
      end.should raise_error
    end
  end

  context "when loading other server difinition" do
    it "should load server definition." do
      subject.register_server :parent, template: true do |server|
        server.log_level "debug"
      end
      subject.register_server :child, 'example.com', load: :parent do |server|
        server.load "file.rb"
      end

      name, data = subject.__server__.assoc(:parent)
      setting = data[:setting]
      setting.value.load.should be_nil

      name, data = subject.__server__.assoc(:child)
      setting = data[:setting]
      setting.value.log_level.should == ["debug"]
      setting.value.load.should == ["file.rb"]
    end

    it "should load server definition that is over ssh." do
      subject.register_server :parent, template: true do |server, ssh|
        server.log_level "debug"
        ssh.rvm "ruby-head"
      end
      subject.register_server :child, 'example.com', load: :parent do |server, ssh|
        server.load "file.rb"
        ssh.nice 20
      end

      name, data = subject.__server__.assoc(:parent)
      setting = data[:setting]
      setting.value.nice.should be_nil
      setting.mode_setting.value.load.should be_nil

      name, data = subject.__server__.assoc(:child)
      setting = data[:setting]
      setting.value.rvm.should == ["ruby-head"]
      setting.value.nice.should == [20]
      setting.mode_setting.value.log_level.should == ["debug"]
      setting.mode_setting.value.load.should == ["file.rb"]
    end

    it "should load server definition on localhost for definition over ssh." do
      subject.register_server :parent, template: true do |server|
        server.log_level "debug"
      end
      subject.register_server :child, 'example.com', load: :parent do |server, ssh|
        server.load "file.rb"
        ssh.nice 20
      end

      name, data = subject.__server__.assoc(:parent)
      setting = data[:setting]
      setting.value.log.should be_nil

      name, data = subject.__server__.assoc(:child)
      setting = data[:setting]
      setting.value.nice.should == [20]
      setting.mode_setting.value.log_level.should == ["debug"]
      setting.mode_setting.value.load.should == ["file.rb"]
    end

    it "should raise error because definition on localhost loads that over ssh." do
      subject.register_server :parent, template: true do |server, ssh|
        server.log_level "debug"
        ssh.rvm "ruby-head"
      end
      lambda do
        subject.register_server :child, 'example.com', load: :parent do |server|
        end
      end.should raise_error
    end
  end

  context "when loading other node difinition" do
    it "should load node definition." do
      subject.register_node :parent, template: true do |node|
        node.log_level "debug"
      end
      subject.register_node :child, load: :parent do |node|
        node.load "file.rb"
      end

      name, data = subject.__node__.assoc(:parent)
      setting = data[:setting]
      setting.value.load.should be_nil

      name, data = subject.__node__.assoc(:child)
      setting = data[:setting]
      setting.value.log_level.should == ["debug"]
      setting.value.load.should == ["file.rb"]
    end

    it "should load node definition that is over ssh." do
      subject.register_node :parent, template: true do |node, ssh|
        node.log_level "debug"
        ssh.rvm "ruby-head"
      end
      subject.register_node :child, load: :parent do |node, ssh|
        node.load "file.rb"
        ssh.nice 20
      end

      name, data = subject.__node__.assoc(:parent)
      setting = data[:setting]
      setting.value.nice.should be_nil
      setting.mode_setting.value.load.should be_nil

      name, data = subject.__node__.assoc(:child)
      setting = data[:setting]
      setting.value.rvm.should == ["ruby-head"]
      setting.value.nice.should == [20]
      setting.mode_setting.value.log_level.should == ["debug"]
      setting.mode_setting.value.load.should == ["file.rb"]
    end

    it "should load node definition on localhost for definition over ssh." do
      subject.register_node :parent, template: true do |node|
        node.log_level "debug"
      end
      subject.register_node :child, load: :parent do |node, ssh|
        node.load "file.rb"
        ssh.nice 20
      end

      name, data = subject.__node__.assoc(:parent)
      setting = data[:setting]
      setting.value.log.should be_nil

      name, data = subject.__node__.assoc(:child)
      setting = data[:setting]
      setting.value.nice.should == [20]
      setting.mode_setting.value.log_level.should == ["debug"]
      setting.mode_setting.value.load.should == ["file.rb"]
    end

    it "should raise error because definition on localhost loads that over ssh." do
      subject.register_node :parent, template: true do |node, ssh|
        node.log_level "debug"
        ssh.rvm "ruby-head"
      end
      lambda do
        subject.register_node :child, load: :parent do |node|
        end
      end.should raise_error
    end

    it "should raise error because group definition is loaded." do
      subject.register_node :parent, group: [:node1, :node2, :node3]
      lambda do
        subject.register_node :child, load: :parent do |node|
        end
      end.should raise_error
    end
  end

  context "when reconfiguring server" do
    it "should reconfigure definition." do
      load_file = 'file.rb'
      subject.register_server(:server1, "example.com") do |server|
        server.load load_file
      end
      subject.register_server(:server1, "example.com") do |server|
        server.log_level 'info'
      end

      name, data = subject.__server__.assoc(:server1)
      data[:type].should == :server
      data[:ssh].should be_false
      data[:template].should be_false
      setting = data[:setting]
      setting.get(:load).should == [load_file]
      setting.get(:log_level).should == ['info']
    end

    it "should raise error for simultaneous reconfiguring and loading." do
      subject.register_server(:server2, "example.com") do |server|
      end
      lambda do
        subject.register_server(:server2, "example.com", load: :some_definition) do |server|
        end
      end.should raise_error
    end
  end

  context "when reconfiguring node" do
    it "should reconfigure definition." do
      load_file = 'file.rb'
      subject.register_node(:node1) do |node|
        node.load load_file
      end
      subject.register_node(:node1) do |node|
        node.log_level 'info'
      end

      name, data = subject.__node__.assoc(:node1)
      data[:type].should == :node
      data[:ssh].should be_false
      data[:template].should be_false
      setting = data[:setting]
      setting.get(:load).should == [load_file]
      setting.get(:log_level).should == ['info']
    end

    it "should raise error to change type of group." do
      nodes = [:node1, :node2]
      nodes2 = [:node3, :node4, :node5]
      subject.register_node(:node_group, :group => nodes)
      subject.register_node(:node_group, :group => nodes2)
      name, data = subject.__node__.assoc(:node_group)
      data[:type].should == :group
      data[:template].should be_true
      data[:ssh].should_not be_true
      data[:args].should == nodes2
    end

    it "should raise error for simultaneous reconfiguring and loading." do
      subject.register_node(:node2) do |node|
      end
      lambda do
        subject.register_node(:node2, load: :some_definition) do |node|
        end
      end.should raise_error
    end

    it "should raise error to change type of group." do
      subject.register_node(:node_group, group: [:node1, :node2])
      lambda do
        subject.register_node(:node_group) do |node|
        end
      end.should raise_error
    end

    it "should raise error to change type of process." do
      subject.register_node(:node) do |node|
      end
      lambda do
        subject.register_node(:node, group: [:node1, :node2])
      end.should raise_error
    end
  end

  context "when clearing" do
    it "should clear servers" do
      subject.register_server(:server1, "example.com") do |server|
      end
      subject.register_server(:server2, "example.com") do |server|
      end
      subject.register_server(:server3, "example.com") do |server|
      end
      subject.clear_server(:server1, :server3)
      subject.__server__.assoc(:server1).should_not be_true
      subject.__server__.assoc(:server2).should be_true
      subject.__server__.assoc(:server3).should_not be_true
    end

    it "should clear nodes" do
      subject.register_node(:node1) do |node|
      end
      subject.register_node(:node2) do |node|
      end
      subject.register_node(:node3) do |node|
      end
      subject.clear_node(:node1, :node3)
      subject.__node__.assoc(:node1).should_not be_true
      subject.__node__.assoc(:node2).should be_true
      subject.__node__.assoc(:node3).should_not be_true
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

    it "should set default nodes." do
      nodes = [:node1, :node2]
      subject.default(:node => nodes)
      h = subject.__default__
      h[:node].should == nodes
    end

    it "should set default value for some keys." do
      subject.default(:log => '/tmp/drbqs/log', :some_key => 'some_value')
      h = subject.__default__
      h[:log].should == '/tmp/drbqs/log'
      h[:some_key].should == 'some_value'
    end

    it "should clear values." do
      subject.default(key1: 'val1', key2: 'val2', key3: 'val3')
      subject.default_clear(:key1, :key2)
      h = subject.__default__
      h[:key1].should be_nil
      h[:key2].should be_nil
      h[:key3].should == 'val3'
    end
  end
end
