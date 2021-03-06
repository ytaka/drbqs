require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'drbqs/server/acl_file'

describe DRbQS::Server::ACLFile do
  it "should return an ACL object" do
    acl = DRbQS::Server::ACLFile.load(File.dirname(__FILE__) + '/data/acl.txt')
    acl.should be_an_instance_of ACL
  end
end
