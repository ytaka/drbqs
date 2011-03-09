require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe DRbQS::Config do
  it "should return nil" do
    DRbQS::Config.set_directory(File.dirname(__FILE__) + '/not_exist_path')
    DRbQS::Config.get_acl_file.should be_nil
  end

  it "should return existing path" do
    path = File.dirname(__FILE__) + '/data'
    DRbQS::Config.set_directory(path)
    DRbQS::Config.get_acl_file.should == File.join(path, 'acl.txt')
  end
end
