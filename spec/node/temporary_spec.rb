require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/node/temporary'

describe DRbQS::Temporary do
  before(:all) do
    DRbQS::Temporary.file
  end

  it "should create base directory." do
    File.exist?(DRbQS::Temporary.root).should be_true
  end

  it "should create empty directory." do
    dir = DRbQS::Temporary.directory
    File.directory?(dir).should be_true
    Dir.entries(dir).should have(2).items
  end

  it "should return new path of file." do
    path = DRbQS::Temporary.file
    File.exist?(path).should_not be_true
    open(path, 'w') do |f|
      f.puts 'hello'
    end
  end

  it "should make directory empty." do
    Dir.entries(DRbQS::Temporary.root).size.should > 2
    DRbQS::Temporary.delete
    Dir.entries(DRbQS::Temporary.root).should have(2).items
  end

  it "should all directories." do
    root = DRbQS::Temporary.root
    DRbQS::Temporary.delete_all
    File.exist?(root).should_not be_true
  end
end
