require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'drbqs/utility/command_line'

[DRbQS::CommandServer, DRbQS::CommandNode, DRbQS::CommandManage, DRbQS::CommandSSH].each do |cls|
  describe cls do
    it "should have defined parse_option." do
      cls.method_defined?(:parse_option).should be_true
    end

    it "should have defined exec." do
      cls.method_defined?(:exec).should be_true
    end
  end
end
