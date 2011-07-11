require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe DRbQS::Config do
  before(:all) do
    FileUtils.mkdir_p(HOME_FOR_SPEC)
  end

  subject do
    DRbQS::Config.new
  end

  it "should create configuration directory." do
    subject
    File.exist?(File.join(HOME_FOR_SPEC, '.drbqs')).should be_true
  end

  it "should save samples" do
    subject.save_sample
    subject.directory.list_in_directory('.').should include('acl.txt.sample')
    subject.directory.list_in_directory('host').should include('host.yaml.sample')
    subject.directory.list_in_directory('shell').should include('bashrc')
  end

  it "should return nil" do
    subject.get_acl_file.should_not be_true
  end

  it "should return path of ACL file" do
    subject.directory.open('acl.txt', 'w') do |f|
    end
    subject.get_acl_file.should == File.join(subject.directory_path, 'acl.txt')
  end

  after(:all) do
    FileUtils.rm_r(HOME_FOR_SPEC)
  end
end
