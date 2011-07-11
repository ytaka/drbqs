require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'drbqs/server/server_hook'

describe DRbQS::ServerHook do
  subject { DRbQS::ServerHook.new }

  it "should add hook" do
    subject.add(:finish) do |server|
      3 + 4
    end.should match(/^finish\d+/)
  end

  it "should add hook with name" do
    name = 'hello'
    subject.add(:finish, name) do |server|
      3 + 4
    end.should == name
  end

  it "should raise error" do
    lambda do
      subject.add(:finish) do |a, b|
        a + b
      end    
    end.should raise_error
  end

  it "should delete hook" do
    name = subject.add(:finish) do |server|
      3 + 4
    end
    subject.hook_names(:finish).should have(1).items
    subject.hook_names(:finish).should include(name)
    subject.delete(:finish, name)
    subject.hook_names(:finish).should be_empty
  end

  it "should delete all hooks" do
    name = subject.add(:finish) do |server|
      3 + 4
    end
    name = subject.add(:finish) do |server|
      5 + 6
    end
    subject.hook_names(:finish).should have(2).items
    subject.delete(:finish)
    subject.hook_names(:finish).should be_empty
  end

  it "should execute hooks" do
    exec_flag = {}
    subject.add(:finish) do |server|
      exec_flag[:first] = true
    end
    subject.add(:finish) do |server|
      exec_flag[:second] = true
    end
    subject.exec(:finish)
    exec_flag[:first].should be_true
    exec_flag[:second].should be_true
  end

  it "should execute finish_exit" do
    execute = nil
    subject.set_finish_exit do
      execute = true
    end
    subject.exec(:finish)
    execute.should be_true
  end
end
