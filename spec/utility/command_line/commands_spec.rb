require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'drbqs/utility/command_line'

[DRbQS::Command::Server, DRbQS::Command::Node, DRbQS::Command::Manage, DRbQS::Command::SSH].each do |cls|
  describe cls do
    it "should have defined parse_option." do
      cls.method_defined?(:parse_option).should be_true
    end

    it "should have defined exec." do
      cls.method_defined?(:exec).should be_true
    end
  end
end
