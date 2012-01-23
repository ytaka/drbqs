require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'drbqs/utility/transfer/transfer'

describe DRbQS::Transfer do
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
    DRbQS::Transfer.empty?.should be_true
  end

  it "should return nil when file queue is empty" do
    DRbQS::Transfer.dequeue_all.should be_nil
  end

  it "should enqueue path." do
    path = create_file('file1.txt', 'file1')
    DRbQS::Transfer.enqueue(path).should == File.basename(path)
    DRbQS::Transfer.dequeue.should == path
  end

  it "should compress and enqueue path." do
    path = create_file('file2.txt', 'file2')
    DRbQS::Transfer.enqueue(path, :compress => true).should == File.basename(path) + '.gz'
    DRbQS::Transfer.dequeue.should == path + '.gz'
  end

  it "should rename and enqueue path." do
    path = create_file('file3.txt', 'file3')
    rename = 'rename.txt'
    new_path = File.join(@tmp, rename)
    DRbQS::Transfer.enqueue(path, :rename => rename)
    DRbQS::Transfer.dequeue.should == new_path
    File.exist?(new_path).should be_true
  end

  it "should rename to some directory." do
    path = create_file('file4.txt', 'file4')
    rename = 'dir/rename.txt'
    new_path = File.join(@tmp, rename)
    DRbQS::Transfer.enqueue(path, :rename => rename).should == File.basename(rename)
    DRbQS::Transfer.dequeue.should == new_path
    File.exist?(new_path).should be_true
  end

  it "should rename, compress, and enqueue path." do
    path = create_file('file5.txt', 'file5')
    rename = 'dir2/rename.txt'
    new_path = File.join(@tmp, rename + '.gz')
    DRbQS::Transfer.enqueue(path, :rename => rename, :compress => true).should == File.basename(rename) + '.gz'
    DRbQS::Transfer.dequeue.should == new_path
    File.exist?(new_path).should be_true
  end

  it "should return array of files" do
    files = [create_file('file6.txt', 'file6'),
             create_file('file8.txt', 'file8'),
             create_file('file8.txt', 'file8')]
    files.each do |path|
      DRbQS::Transfer.enqueue(path).should == File.basename(path)
    end
    DRbQS::Transfer.dequeue_all.should == files
    DRbQS::Transfer.empty?.should be_true
  end

  it "should enqueue path of directory." do
    path = create_directory('dir/dir1')
    DRbQS::Transfer.enqueue(path).should == File.basename(path)
    DRbQS::Transfer.dequeue.should == path
  end

  it "should compress and enqueue path of directory." do
    path = create_directory('dir/dir2')
    file_path = create_file('dir/dir2/test.txt', 'hello world')
    DRbQS::Transfer.enqueue(path, :compress => true).should == File.basename(path) + '.tar.gz'
    DRbQS::Transfer.dequeue.should == path + '.tar.gz'
  end

  it "should rename, compress, and enqueue path of directory." do
    path = create_directory('dir/dir3')
    file_path = create_file('dir/dir3/test.txt', 'hello world')
    rename = 'rename_dir'
    DRbQS::Transfer.enqueue(path, :compress => true, :rename => rename).should == rename + '.tar.gz'
    DRbQS::Transfer.dequeue.should == File.join(@tmp, 'dir', rename + '.tar.gz')
  end

  it "should return nil for a nonexistent file." do
    DRbQS::Transfer.enqueue("nonexistent/file.txt").should be_nil
    DRbQS::Transfer.empty?.should be_true
  end

  it "should return nil for a nonexistent file with a compress option." do
    DRbQS::Transfer.enqueue("nonexistent/file.txt", :compress => true).should be_nil
    DRbQS::Transfer.empty?.should be_true
  end

  it "should return nil for a nonexistent file with a rename option." do
    DRbQS::Transfer.enqueue("nonexistent/file.txt", :rename => "hello.txt").should be_nil
    DRbQS::Transfer.empty?.should be_true
  end

  after(:all) do
    FileUtils.rm_r(@tmp)
  end

end
