require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'drbqs/utility/temporary'
require 'drbqs/utility/transfer/transfer'
require 'drbqs/utility/transfer/transfer_client'

def create_sample_transfer_files(n = nil)
  tmp_dir = DRbQS::Temporary.directory
  files = []
  (n || 3).times do |i|
    path = File.join(tmp_dir, "test%d.txt" % i)
    files << path
    open(path, 'w') do |f|
      f.puts (i * i).to_s
    end
  end
  [tmp_dir, files]
end

describe DRbQS::Transfer::Client::Local do
  before(:all) do
    @dir = DRbQS::Temporary.directory
    @client = DRbQS::Transfer::Client::Local.new(@dir)
  end

  it "should move files." do
    tmp_dir, files = create_sample_transfer_files
    @client.transfer(files)
    files.all? do |path|
      !File.exist?(path)
    end.should be_true
    files.all? do |path|
      File.exist?(File.join(@dir, File.basename(path)))
    end.should be_true
  end

  it "should copy files." do
    tmp_dir, files = create_sample_transfer_files
    @client.download(files)
    files.all? do |path|
      File.exist?(path)
    end.should be_true
    files.all? do |path|
      File.exist?(File.join(@dir, File.basename(path)))
    end.should be_true
  end

  after(:all) do
    DRbQS::Temporary.delete_all
  end
end

describe DRbQS::Transfer::Client::SFTP do
  module Net::SFTP
    def self.set_mock(m)
      @mock = m
    end

    def self.start(user, host, &block)
      yield(@mock)
    end
  end

  before(:all) do
    @dir = DRbQS::Temporary.directory
    @client = DRbQS::Transfer::Client::SFTP.new('user_name', 'example.com', @dir)
  end

  it "should transfer files." do
    tmp_dir, files = create_sample_transfer_files(1)
    source_path = files[0]
    sftp = double('sftp')
    sftp.should_receive(:upload).with(source_path, File.join(@dir, File.basename(source_path)))
    FileUtils.should_receive(:rm_r).with(source_path)
    Net::SFTP.set_mock(sftp)
    @client.transfer(files)
  end

  it "should download files. (incomplete)" do
    tmp_dir, files = create_sample_transfer_files(1)
    sftp = double('sftp')
    sftp.should_receive(:download)
    Net::SFTP.set_mock(sftp)
    @client.download(files)
  end

  after(:all) do
    DRbQS::Temporary.delete_all
  end
end
