require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/execute/process_define'

describe DRbQS::ProcessDefinition do
  subject do
    DRbQS::ProcessDefinition.new
  end

  context "when registering processes" do
    it "should register server" do
      subject.load(File.join(File.dirname(__FILE__), 'def/execute1.rb'))
      p subject.register.__server__
      p subject.register.__node__
    end
  end
end
