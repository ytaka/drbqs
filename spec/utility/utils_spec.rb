require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DRbQS::Utils do
  it "should return ramdom key" do
    a = DRbQS::Utils.random_key
    b = DRbQS::Utils.random_key
    a.should be_an_instance_of String
    b.should be_an_instance_of String
    a.should_not == b
  end
end
