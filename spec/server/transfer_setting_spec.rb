require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/utility/temporary'

describe DRbQS::Server::TransferSetting do
  context "when setup does not execute" do
    it "should return nil." do
      setting = DRbQS::Server::TransferSetting.new('example.com', 'user', nil)
      setting.setup_server(nil).should be_nil
    end
  end

  context "when setup transfer settings" do
    it "should set transfer settings by initializing." do
      dir = DRbQS::Temporary.file
      setting = DRbQS::Server::TransferSetting.new('example.com', 'user', dir)
      setting.setup_server(nil).should be_true
      setting.user.should == 'user'
      setting.host.should == 'example.com'
      setting.directory.should == dir
    end

    it "should set directory by setup_server." do
      dir = DRbQS::Temporary.file
      setting = DRbQS::Server::TransferSetting.new('example.com', 'user', nil)
      setting.setup_server(dir).should be_true
      setting.user.should == 'user'
      setting.host.should == 'example.com'
      setting.directory.should == dir
    end

    it "should not set sftp settings." do
      dir = DRbQS::Temporary.file
      setting = DRbQS::Server::TransferSetting.new(nil, nil, dir)
      setting.setup_server(nil).should be_true
      setting.host.should be_nil
      setting.directory.should == dir
    end
  end

  context "when creating transfer client" do
    it "should return nil because setup is not executed." do
      dir = DRbQS::Temporary.file
      setting = DRbQS::Server::TransferSetting.new('example.com', 'user', dir)
      setting.get_client(true).should be_nil
    end
    
    it "should return local and sftp transfer client." do
      dir = DRbQS::Temporary.file
      setting = DRbQS::Server::TransferSetting.new('example.com', 'user', dir)
      setting.setup_server(nil).should be_true
      client = setting.get_client(true)
      client.directory.should == dir
      client.local.should be_an_instance_of DRbQS::Transfer::Client::Local
      client.sftp.should be_an_instance_of DRbQS::Transfer::Client::SFTP
    end
    
    it "should return only local transfer client." do
      dir = DRbQS::Temporary.file
      setting = DRbQS::Server::TransferSetting.new(nil, nil, dir)
      setting.setup_server(nil).should be_true
      client = setting.get_client(true)
      client.directory.should == dir
      client.local.should be_an_instance_of DRbQS::Transfer::Client::Local
      client.sftp.should be_nil
    end
  end

  after(:all) do
    DRbQS::Temporary.delete_all
  end
end
