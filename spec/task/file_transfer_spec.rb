require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/utility/transfer/file_transfer'

describe DRbQS::FileTransfer do
  def create_file(path, str)
    path = File.join(@tmp, path)
    open(path, 'w') do |f|
      f.puts str
    end
    path
  end

  def create_directory(path)
    path = File.join(@tmp, path)
    FileUtils.mkdir_p(path)
    path
  end

  before(:all) do
    @tmp = FileName.create('/tmp/drbqs_test', :directory => :self)
  end

  it "should be empty." do
    DRbQS::FileTransfer.empty?.should be_true
  end

  it "should return nil when file queue is empty" do
    DRbQS::FileTransfer.dequeue_all.should be_nil
  end

  it "should enqueue path." do
    path = create_file('file1.txt', 'file1')
    DRbQS::FileTransfer.enqueue(path)
    DRbQS::FileTransfer.dequeue.should == path
  end

  it "should compress and enqueue path." do
    path = create_file('file2.txt', 'file2')
    DRbQS::FileTransfer.enqueue(path, :compress => true)
    DRbQS::FileTransfer.dequeue.should == path + '.gz'
  end

  it "should rename and enqueue path." do
    path = create_file('file3.txt', 'file3')
    rename = 'rename.txt'
    new_path = File.join(@tmp, rename)
    DRbQS::FileTransfer.enqueue(path, :rename => rename)
    DRbQS::FileTransfer.dequeue.should == new_path
    File.exist?(new_path).should be_true
  end

  it "should rename to some directory." do
    path = create_file('file4.txt', 'file4')
    rename = 'dir/rename.txt'
    new_path = File.join(@tmp, rename)
    DRbQS::FileTransfer.enqueue(path, :rename => rename)
    DRbQS::FileTransfer.dequeue.should == new_path
    File.exist?(new_path).should be_true
  end

  it "should rename, compress, and enqueue path." do
    path = create_file('file5.txt', 'file5')
    rename = 'dir2/rename.txt'
    new_path = File.join(@tmp, rename + '.gz')
    DRbQS::FileTransfer.enqueue(path, :rename => rename, :compress => true)
    DRbQS::FileTransfer.dequeue.should == new_path
    File.exist?(new_path).should be_true
  end

  it "should return array of files" do
    files = [create_file('file6.txt', 'file6'),
             create_file('file8.txt', 'file8'),
             create_file('file8.txt', 'file8')]
    files.each do |path|
      DRbQS::FileTransfer.enqueue(path)
    end
    DRbQS::FileTransfer.dequeue_all.should == files
    DRbQS::FileTransfer.empty?.should be_true
  end

  it "should enqueue path of directory." do
    path = create_directory('dir/dir1')
    DRbQS::FileTransfer.enqueue(path)
    DRbQS::FileTransfer.dequeue.should == path
  end

  it "should compress and enqueue path of directory." do
    path = create_directory('dir/dir2')
    file_path = create_file('dir/dir2/test.txt', 'hello world')
    DRbQS::FileTransfer.enqueue(path, :compress => true)
    DRbQS::FileTransfer.dequeue.should == path + '.tar.gz'
  end

  it "should rename, compress, and enqueue path of directory." do
    path = create_directory('dir/dir3')
    file_path = create_file('dir/dir3/test.txt', 'hello world')
    rename = 'rename_dir'
    DRbQS::FileTransfer.enqueue(path, :compress => true, :rename => rename)
    DRbQS::FileTransfer.dequeue.should == File.join(@tmp, 'dir', rename + '.tar.gz')
  end

  after(:all) do
    FileUtils.rm_r(@tmp)
  end

end
