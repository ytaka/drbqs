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
    FileUtils.rm(path)
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
    FileUtils.rm(path)
  end

  it "should return nil for invalid extension." do
    path = File.join(@dir, 'host3.txt')
    data = { :abc => 123 }
    open(path, 'w') do |f|
      f.print YAML.dump(data)
    end
    subject.get_options('host3').should == [nil, {}]
    FileUtils.rm(path)
  end

  it "should return list of names." do
    names = ['name1', 'name2', 'name3']
    files = names.map do |n|
      File.join(@dir, n + '.yaml')
    end
    data = { :abc => 123 }
    files.each do |path|
      open(path, 'w') do |f|
        f.print YAML.dump(data)
      end
    end
    subject.config_names.should == names.sort
    FileUtils.rm(files)
  end

  it "should return only path." do
    path = File.join(@dir, 'host4.yml')
    data = { :abc => 123 }
    open(path, 'w') do |f|
      f.print YAML.dump(data)
    end
    subject.get_path('host4').should == path
    FileUtils.rm(path)
  end

  after(:all) do
    DRbQS::Temporary.delete
  end
end
