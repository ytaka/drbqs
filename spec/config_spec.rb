require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe DRbQS::Config do
  before(:all) do
    @home = File.join(File.dirname(__FILE__), 'test_config')
    DRbQS::Config.set_home_directory(@home)
  end

  subject do
    DRbQS::Config.new
  end

  it "should create configuration directory." do
    subject
    File.exist?(File.join(@home, '.drbqs')).should be_true
  end

  it "should save samples" do
    subject.save_sample
    subject.list_in_directory('.').should include('acl.txt.sample')
    subject.list_in_directory('host').should include('host.yaml.sample')
    subject.list_in_directory('shell').should include('bashrc')
  end

  it "should return nil" do
    subject.get_acl_file.should_not be_true
  end

  it "should return path of ACL file" do
    subject.open('acl.txt', 'w') do |f|
    end
    subject.get_acl_file.should == File.join(subject.directory, 'acl.txt')
  end

  after(:all) do
    FileUtils.rm_r(@home)
  end
end
