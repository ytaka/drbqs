require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe DRbQS::FileTransfer do
  it "should enqueue path" do
    DRbQS::FileTransfer.enqueue('hello/world')
    DRbQS::FileTransfer.empty?.should_not be_true
  end

  it "should dequeue path" do
    DRbQS::FileTransfer.dequeue.should == 'hello/world'
    DRbQS::FileTransfer.empty?.should be_true
  end
end
