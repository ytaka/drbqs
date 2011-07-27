require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/manage/ssh_shell'

describe DRbQS::Manage::SSHShell do
  it "should split destination" do
    ssh = DRbQS::Manage::SSHShell.new('user@hostname')
    ssh.user.should == 'user'
    ssh.host.should == 'hostname'
    ssh.port.should be_nil
    ssh.directory.should be_nil
  end

  it "should split destination including directory" do
    ssh = DRbQS::Manage::SSHShell.new('user@hostname:22', :directory => '/path/to/directory')
    ssh.user.should == 'user'
    ssh.host.should == 'hostname'
    ssh.port.should == 22
    ssh.directory.should == '/path/to/directory'
  end

  it "should raise error: not include '@'" do
    lambda do
      DRbQS::Manage::SSHShell.new('userhostname')
    end.should raise_error
  end

  it "should raise error: empty user name" do
    lambda do
      DRbQS::Manage::SSHShell.new('@hostname')
    end.should raise_error
  end

  it "should raise error: empty host name" do
    lambda do
      DRbQS::Manage::SSHShell.new('user:22')
    end.should raise_error
  end

end
