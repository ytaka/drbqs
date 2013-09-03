require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/execute/process_define'

describe DRbQS::ProcessDefinition do
  def definition_file(name)
    File.join(File.dirname(__FILE__), 'def', name)
  end

  context "when creating without default process names" do
    before(:all) do
      @process_def = DRbQS::ProcessDefinition.new(nil, nil, nil)
      @process_def.load(definition_file('execute1.rb'))
      @info = @process_def.information
    end

    subject do
      @process_def
    end

    it "should get server list." do
      data = @info[:server].assoc(:server_local)[1]
      data[:type].should == :server
      data[:ssh].should_not be_true
      data[:args].should == ["localhost"]

      data = @info[:server].assoc(:server_ssh)[1]
      data[:type].should == :server
      data[:ssh].should be_true
      data[:args].should == ["example.com"]
    end

    it "should get node list." do
      data = @info[:node].assoc(:node_local)[1]
      data[:type].should == :node
      data[:ssh].should_not be_true
      data[:args].should == []

      data = @info[:node].assoc(:node_ssh)[1]
      data[:type].should == :node
      data[:ssh].should be_true
      data[:args].should == []
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
    before(:all) do
      @process_def = DRbQS::ProcessDefinition.new(nil, nil, nil)
      @process_def.load(definition_file('no_def.rb'))
      @info = @process_def.information
    end

    subject do
      @process_def
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

  context "when execute all nodes" do
    before(:all) do
      @port = 11111
      @hostname = 'localhost'     # defined in execute1.rb
      @tmp = '/tmp/drbqs_tmp_log' # defined in execute1.rb
      @process_def = DRbQS::ProcessDefinition.new(nil, nil, @port)
      @process_def.load(definition_file('execute1.rb'))
      @server_setting = @process_def.__send__(:get_server_setting)[1][:setting]
      @node_local_setting = @process_def.__send__(:get_node_data, :node_local)[:setting]
      @node_ssh_setting = @process_def.__send__(:get_node_data, :node_ssh)[:setting]
    end

    subject do
      @process_def
    end

    it "should check port number of server." do
      @server_setting.should_receive(:exec)
      subject.execute_server([])
      @server_setting.get_first(:port).should == @port
    end

    it "should check port number set in node." do
      @node_local_setting.should_receive(:exec)
      @node_ssh_setting.should_receive(:exec)
      subject.execute_node
      uri = "druby://#{@hostname}:#{@port}"
      @node_local_setting.value.argument.should == [uri]
      @node_ssh_setting.mode_setting.value.argument == [uri]
    end

    after(:all) do
      FileUtils.rm_r(@tmp)
    end
  end

  context "when execute a specified node" do
    before(:all) do
      @port = DRbQS::ROOT_DEFAULT_PORT
      @hostname = 'localhost'     # defined in execute1.rb
      @tmp = '/tmp/drbqs_tmp_log' # defined in execute1.rb
      @process_def = DRbQS::ProcessDefinition.new(nil, [:node_local], nil)
      @process_def.load(definition_file('execute1.rb'))
      @server_setting = @process_def.__send__(:get_server_setting)[1][:setting]
      @node_local_setting = @process_def.__send__(:get_node_data, :node_local)[:setting]
    end

    subject do
      @process_def
    end

    it "should check port number of server." do
      @server_setting.should_receive(:exec)
      subject.execute_server([])
      @server_setting.get_first(:port).should == @port
    end

    it "should check port number set in node." do
      @node_local_setting.should_receive(:exec)
      subject.execute_node
      uri = "druby://#{@hostname}:#{@port}"
      @node_local_setting.value.argument.should == [uri]
    end

    after(:all) do
      FileUtils.rm_r(@tmp)
    end
  end

  context "when execute default nodes" do
    before(:all) do
      @port = DRbQS::ROOT_DEFAULT_PORT
      @hostname = 'localhost'     # defined in execute1.rb
      @tmp = '/tmp/drbqs_tmp_log' # defined in execute1.rb
      @process_def = DRbQS::ProcessDefinition.new(nil, nil, nil)
      @process_def.load(definition_file('execute2.rb'))
      @server_setting = @process_def.__send__(:get_server_setting)[1][:setting]
      @node_local_setting = @process_def.__send__(:get_node_data, :node_local)[:setting]
      @node_ssh_setting = @process_def.__send__(:get_node_data, :node_ssh)[:setting]
    end

    subject do
      @process_def
    end

    it "should check port number set in node." do
      @node_local_setting.should_not_receive(:exec)
      @node_ssh_setting.should_receive(:exec)
      subject.execute_node
    end
  end
end
