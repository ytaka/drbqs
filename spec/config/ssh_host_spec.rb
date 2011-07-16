require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/config/config'
require 'drbqs/utility/temporary'

describe DRbQS::Config::SSHHost do
  before(:all) do
    @dir = DRbQS::Temporary.directory
  end

  subject do
    DRbQS::Config::SSHHost.new(@dir)
  end

  it "should return empty data" do
    subject.get_options('host0').should == [nil, {}]
  end

  it "should return path with extension '\.yaml'." do
    path = File.join(@dir, 'host1.yaml')
    data = { :abc => 123 }
    open(path, 'w') do |f|
      f.print YAML.dump(data)
    end
    ary = subject.get_options('host1')
    ary[0].should == path
    ary[1].should == data
  end

  it "should return path with extension '\.yml'." do
    path = File.join(@dir, 'host2.yml')
    data = { :abc => 123 }
    open(path, 'w') do |f|
      f.print YAML.dump(data)
    end
    ary = subject.get_options('host2')
    ary[0].should == path
    ary[1].should == data
  end

  it "should return nil for invalid extension." do
    path = File.join(@dir, 'host3.txt')
    data = { :abc => 123 }
    open(path, 'w') do |f|
      f.print YAML.dump(data)
    end
    subject.get_options('host3').should == [nil, {}]
  end

  after(:all) do
    DRbQS::Temporary.delete_all
  end
end
