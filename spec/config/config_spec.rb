require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DRbQS::Config do
  before(:all) do
    FileUtils.mkdir_p(HOME_FOR_SPEC)
  end

  subject do
    DRbQS::Config.new
  end

  context "when setting new homedirectory" do
    before(:all) do
      @old_home_directory = DRbQS::Config.get_home_directory
    end

    it "should change home directory." do
      new_home_directory = '/tmp/drbqs_new_home'
      DRbQS::Config.set_home_directory(new_home_directory)
      DRbQS::Config.get_home_directory.should == new_home_directory
    end

    after(:all) do
      DRbQS::Config.set_home_directory(@old_home_directory)
    end
  end

  context "when creating configuration directory" do
    before(:all) do
      @dir = File.join(HOME_FOR_SPEC, '.drbqs')
      FileUtils.rm_r(@dir) if File.exist?(@dir)
    end

    it "should get directory existing." do
      lambda do
        subject
      end.should change { File.exist?(@dir) }.from(false).to(true)
    end
  end

  context "when saving samples" do
    before(:all) do
      subject.save_sample
    end

    it "should get sample of ACL file." do
      subject.directory.list_in_directory('.').should include('acl.txt.sample')
    end

    it "should get sample of host file." do
      subject.directory.list_in_directory('host').should include('host.yaml.sample')
    end

    it "should get bashrc for SSH of drbqs." do
      subject.directory.list_in_directory('shell').should include('bashrc')
    end
  end

  context "when managing ACL file" do
    before(:all) do
      @path = subject.directory.file_path('acl.txt')
      FileUtils.rm(@path) if File.exist?(@path)
    end

    it "should not have ACL file by default." do
      subject.get_acl_file.should_not be_true
    end

    it "should return path of ACL file" do
      open(@path, 'w') do |f|
      end
      subject.get_acl_file.should == File.join(@path)
      FileUtils.rm(@path) if File.exist?(@path)
    end
  end

  it "should return DRbQS::Config::SSHHost object." do
    subject.ssh_host.should be_an_instance_of DRbQS::Config::SSHHost
  end

  after(:all) do
    FileUtils.rm_r(HOME_FOR_SPEC)
  end
end
