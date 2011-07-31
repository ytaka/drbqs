require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'drbqs/utility/transfer/transfer'
require 'drbqs/utility/transfer/transfer_client'
require 'drbqs/utility/transfer/transfer_file_list'

describe DRbQS::Transfer::FileList do
  before(:all) do
    @files = Dir.glob("#{File.dirname(__FILE__)}/*.rb")
  end

  it "should download files." do
    client = mock('transfer client')
    DRbQS::Transfer::Client.stub(:get).and_return(client)
    client.should_receive(:download).with(@files, nil)
    file_list = DRbQS::Transfer::FileList.new(*@files)
    file_list.path
  end

  it "should download files with readonly." do
    client = mock('transfer client')
    DRbQS::Transfer::Client.stub(:get).and_return(client)
    client.should_receive(:download).with(@files, true)
    file_list = DRbQS::Transfer::FileList.new(*@files, :readonly => true)
    file_list.path
  end
end
