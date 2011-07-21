require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/server/server_hook'

describe DRbQS::Server::Hook do
  subject { DRbQS::Server::Hook.new }

  it "should add a hook with automatic creation of name." do
    n = subject.number_of_hook(:finish)
    name = subject.add(:finish) do |server|
      3 + 4
    end
    name.should match(/^finish\d+/)
    subject.number_of_hook(:finish).should == (n + 1)
  end

  it "should add a hook with name." do
    n = subject.number_of_hook(:finish)
    name = 'hello'
    name_new = subject.add(:finish, name) do |server|
      3 + 4
    end
    name_new.should == name
    subject.number_of_hook(:finish).should == (n + 1)
  end

  it "should raise error for invalid number of block arguments." do
    lambda do
      subject.add(:finish) do |a, b|
        a + b
      end    
    end.should raise_error
  end

  it "should delete a hook." do
    name = subject.add(:finish) do |server|
      3 + 4
    end
    subject.number_of_hook(:finish).should == 1
    subject.hook_names(:finish).should include(name)
    subject.delete(:finish, name)
    subject.hook_names(:finish).should be_empty
  end

  it "should delete all hooks." do
    name = subject.add(:finish) do |server|
      3 + 4
    end
    name = subject.add(:finish) do |server|
      5 + 6
    end
    subject.number_of_hook(:finish).should == 2
    subject.delete(:finish)
    subject.hook_names(:finish).should be_empty
  end

  it "should execute hooks." do
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

  it "should execute finish_exit that is special proc." do
    execute = nil
    subject.set_finish_exit do
      execute = true
    end
    subject.exec(:finish)
    execute.should be_true
  end

  context "when checking block before executing hook" do
    it "should execute hooks." do
      exec_flag = {}
      subject.add(:finish) do |server|
        exec_flag[:first] = true
      end
      subject.add(:finish) do |server|
        exec_flag[:second] = true
      end
      subject.exec(:finish) do |name|
        name.should be_an_instance_of String
        true
      end
      exec_flag[:first].should be_true
      exec_flag[:second].should be_true
    end

    it "should execute finish_exit that is special proc." do
      execute = nil
      subject.set_finish_exit do
        execute = true
      end
      subject.exec(:finish) do |name|
        name.should be_an_instance_of String
        true
      end
      execute.should be_true
    end

    it "should not execute hooks." do
      exec_flag = {}
      subject.add(:finish) do |server|
        exec_flag[:first] = true
      end
      subject.add(:finish) do |server|
        exec_flag[:second] = true
      end
      subject.exec(:finish) do |name|
        name.should be_an_instance_of String
        false
      end
      exec_flag[:first].should be_nil
      exec_flag[:second].should be_nil
    end

    it "should not execute finish_exit that is special proc." do
      execute = nil
      subject.set_finish_exit do
        execute = true
      end
      subject.exec(:finish) do |name|
        name.should be_an_instance_of String
        false
      end
      execute.should be_nil
    end
  end
end
