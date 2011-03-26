require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe DRbQS::Server do
  context "when we initialize DRbQS::Server" do
    it "should initialize an ACL object by ACLFile.load" do
      path = File.dirname(__FILE__) + '/data/acl.txt'
      DRbQS::ACLFile.should_receive(:load).with(path)
      DRbQS::Server.new(:acl => path, :log_file => nil)
    end

    it "should initialize an ACL object by ACL.new" do
      ary = ['deny', 'all', 'allow', 'localhost']
      ACL.should_receive(:new).with(ary)
      DRbQS::Server.new(:acl => ary, :log_file => nil)
    end
  end

  context "when we start DRbQS::Server" do
    it "should not set DRbQS::FileTransfer" do
      server = DRbQS::Server.new
      DRbQS::Transfer.should_not_receive(:new)
      DRb.should_receive(:start_service).once
      server.start
    end

    it "should set defalt settings of DRbQS::FileTransfer" do
      server = DRbQS::Server.new(:file_directory => '/tmp')
      DRbQS::Transfer.should_receive(:new).with(ENV['USER'], 'localhost', '/tmp')
      DRb.should_receive(:start_service).once
      server.start
    end

    it "should set DRbQS::FileTransfer" do
      server = DRbQS::Server.new(:file_directory => '/tmp', :scp_user => 'hello', :scp_host => 'example.com')
      DRbQS::Transfer.should_receive(:new).with('hello', 'example.com', '/tmp')
      DRb.should_receive(:start_service).once
      server.start
    end

    it "should set DRbQS::FileTransfer by DRbQS::Server#set_file_transfer" do
      server = DRbQS::Server.new
      DRbQS::Transfer.should_receive(:new).with(ENV['USER'], 'localhost', '/tmp')
      DRb.should_receive(:start_service).once
      server.set_file_transfer('/tmp')
      server.start
    end

    it "should set DRbQS::FileTransfer by DRbQS::Server#set_file_transfer with optional arguments" do
      server = DRbQS::Server.new
      DRbQS::Transfer.should_receive(:new).with('hello', 'example.com', '/tmp')
      DRb.should_receive(:start_service).once
      server.set_file_transfer('/tmp', :user => 'hello', :host => 'example.com')
      server.start
    end
  end
end
