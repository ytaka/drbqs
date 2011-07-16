  # it "should execute over ssh" do
  #   command = "ls /"
  #   ssh_shell = mock
  #   DRbQS::Manage::SSHShell.stub!(:new).and_return(ssh_shell)
  #   ssh_shell.should_receive(:start).with(command)
  #   @manage.execute_over_ssh("user@localhost", {}, command)
  # end
