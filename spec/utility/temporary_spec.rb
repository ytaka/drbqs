require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/utility/temporary'

describe DRbQS::Temporary do
  before(:all) do
    DRbQS::Temporary.file
  end

  subject do
    DRbQS::Temporary
  end

  it "should create base directory." do
    File.exist?(subject.root).should be_true
  end

  it "should create empty directory." do
    dir = subject.directory
    File.directory?(dir).should be_true
    Dir.entries(dir).should have(2).items
  end

  it "should return new path of file." do
    path = subject.file
    File.exist?(path).should_not be_true
    open(path, 'w') do |f|
      f.puts 'hello'
    end
  end

  it "should set subdirectory." do
    subject.set_sub_directory('abc')
    subject.subdirectory.should be_nil
  end

  it "should get directory in subdirectory." do
    subject.set_sub_directory('ABCD')
    dir = subject.directory
    File.exist?(subject.subdirectory).should be_true
    dir.should match(/\/ABCD/)
  end

  it "should get file name in subdirectory." do
    subject.set_sub_directory('EFGH')
    file = subject.file
    File.exist?(subject.subdirectory).should be_true
    file.should match(/\/EFGH\//)
  end

  it "should delete all directories." do
    root = subject.root
    subject.delete
    File.exist?(root).should_not be_true
  end
end
