require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'drbqs/utility/temporary'
require 'drbqs/utility/transfer/transfer'
require 'drbqs/utility/transfer/transfer_client'

describe DRbQS::Transfer::Client::Local do
  def create_sample_files
    tmp_dir = DRbQS::Temporary.directory
    files = []
    3.times do |i|
      path = File.join(tmp_dir, "test%d.txt" % i)
      files << path
      open(path, 'w') do |f|
        f.puts (i * i).to_s
      end
    end
    [tmp_dir, files]
  end

  before(:all) do
    @dir = DRbQS::Temporary.directory
    @client = DRbQS::Transfer::Client::Local.new(@dir)
  end

  it "should move files." do
    tmp_dir, files = create_sample_files
    @client.transfer(files)
    files.all? do |path|
      !File.exist?(path)
    end.should be_true
    files.all? do |path|
      File.exist?(File.join(@dir, File.basename(path)))
    end.should be_true
  end

  it "should copy files." do
    tmp_dir, files = create_sample_files
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

  after(:all) do
    DRbQS::Temporary.delete_all
  end
end
