require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/utility/temporary'

describe DRbQS::Server::TransferSetting do
  it "should return nil." do
    setting = DRbQS::Server::TransferSetting.new('example.com', 'user', nil)
    setting.create(nil).should be_nil
  end

  it "should return transfer client." do
    dir = DRbQS::Temporary.file
    setting = DRbQS::Server::TransferSetting.new('example.com', 'user', dir)
    client = setting.create(nil)
    client.should be_an_instance_of DRbQS::Transfer::Client
    client.sftp.should be_an_instance_of DRbQS::Transfer::Client::SFTP
    setting.create(nil).should be_nil
  end

  it "should return transfer client with a directory argument." do
    dir = DRbQS::Temporary.file
    setting = DRbQS::Server::TransferSetting.new('example.com', 'user', nil)
    client = setting.create(dir)
    client.should be_an_instance_of DRbQS::Transfer::Client
    client.sftp.should be_an_instance_of DRbQS::Transfer::Client::SFTP
    setting.create(dir).should be_nil
  end

  it "should return transfer client without sftp" do
    dir = DRbQS::Temporary.file
    setting = DRbQS::Server::TransferSetting.new(nil, nil, dir)
    client = setting.create(nil)
    client.should be_an_instance_of DRbQS::Transfer::Client
    client.sftp.should be_nil
    setting.create(nil).should be_nil
  end
end
