require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DRbQS::Server do
  context "when loading ACL for druby" do
    it "should initialize an ACL object by ACLFile.load" do
      path = File.dirname(__FILE__) + '/data/acl.txt'
      DRbQS::Server::ACLFile.should_receive(:load).with(path)
      DRbQS::Server.new(:acl => path, :log_file => nil)
    end

    it "should initialize an ACL object by ACL.new" do
      ary = ['deny', 'all', 'allow', 'localhost']
      ACL.should_receive(:new).with(ary)
      DRbQS::Server.new(:acl => ary, :log_file => nil)
    end
  end

  context "when we initialize uri of server" do
    it "should raise error for existing path" do
      lambda do
        DRbQS::Server.new(:unix => __FILE__)
      end.should raise_error
    end

    it "should raise error for none of parent directory" do
      lambda do
        DRbQS::Server.new(:unix => "not_exist/dir/abc")
      end.should raise_error
    end

    it "should get default uri" do
      server = DRbQS::Server.new
      server.uri.should == "druby://:#{DRbQS::ROOT_DEFAULT_PORT}"
    end

    it "should get uri of tcp" do
      server = DRbQS::Server.new(:port => 9999)
      server.uri.should == "druby://:9999"
    end

    it "should get uri of unix domain" do
      server = DRbQS::Server.new(:unix => "/tmp/drbqs")
      server.uri.should == "drbunix:/tmp/drbqs"
    end

    it "should prefer port number option" do
      server = DRbQS::Server.new(:unix => "/tmp/drbqs", :port => 9999)
      server.uri.should == "druby://:9999"
    end
  end

  context "when initializing server" do
    it "should call set_signal_trap." do
      Signal.should_receive(:trap).with(:TERM)
      DRbQS::Server.new(:signal_trap => true)
    end

    it "should set finish hook" do
      server_hook = mock
      DRbQS::Server::Hook.stub!(:new).and_return(server_hook)
      server_hook.should_receive(:set_finish_exit)
      DRbQS::Server.new(:finish_exit => true)
    end
  end

  context "when starting DRbQS::Server" do
    it "should not set DRbQS::FileTransfer" do
      server = DRbQS::Server.new
      DRbQS::Transfer::Client.should_not_receive(:new)
      DRb.should_receive(:start_service).once
      server.start
    end

    it "should set DRbQS::FileTransfer" do
      server = DRbQS::Server.new(:file_directory => '/tmp', :sftp_user => 'hello', :sftp_host => 'example.com')
      DRbQS::Transfer::Client::SFTP.should_receive(:new).with('hello', 'example.com', '/tmp')
      DRb.should_receive(:start_service).once
      server.start
    end

    it "should set DRbQS::FileTransfer by DRbQS::Server#set_file_transfer with optional arguments" do
      server = DRbQS::Server.new
      DRbQS::Transfer::Client::SFTP.should_receive(:new).with('hello', 'example.com', '/tmp')
      DRb.should_receive(:start_service).once
      server.set_file_transfer('/tmp', :user => 'hello', :host => 'example.com')
      server.start
    end
  end
end
