require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'drbqs/ssh_shell'

describe DRbQS::SSHShell do
  it "should split destination" do
    ssh = DRbQS::SSHShell.new('user@hostname')
    ssh.user.should == 'user'
    ssh.host.should == 'hostname'
    ssh.directory.should be_nil
  end

  it "should split destination including directory" do
    ssh = DRbQS::SSHShell.new('user@hostname:/path/to/directory')
    ssh.user.should == 'user'
    ssh.host.should == 'hostname'
    ssh.directory.should == '/path/to/directory'
  end

  it "should raise error: not include '@'" do
    lambda do
      DRbQS::SSHShell.new('userhostname:/path/to/directory')
    end.should raise_error
  end

  it "should raise error: empty user name" do
    lambda do
      DRbQS::SSHShell.new('@hostname:/path/to/directory')
    end.should raise_error
  end

  it "should raise error: empty host name" do
    lambda do
      DRbQS::SSHShell.new('user:/path/to/directory')
    end.should raise_error
  end

end
