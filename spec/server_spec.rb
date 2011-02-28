require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe DRbQS::Server do
  context "when we setup ACL objects" do
    it "should initialize an ACL object by ACLFile.load" do
      path = File.dirname(__FILE__) + '/data/acl.txt'
      DRbQS::ACLFile.should_receive(:load).with(path)
      DRbQS::Server.new(:acl => path)
    end

    it "should initialize an ACL object by ACL.new" do
      ary = ['deny', 'all', 'allow', 'localhost']
      ACL.should_receive(:new).with(ary)
      DRbQS::Server.new(:acl => ary)
    end
  end
end
