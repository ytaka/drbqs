require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/config/config'

describe DRbQS::ProcessList::Server do
  before(:all) do
    @dir = File.join(File.dirname(__FILE__), 'tmp_process_list/server')
    FileUtils.mkdir_p(@dir)
  end

  subject do
    DRbQS::ProcessList::Server.new(@dir)
  end

  it "should save data" do
    uri = 'druby://:13000'
    h = { :pid => 1111 }
    subject.save(uri, h)
    subject.get(uri).should == h
  end

  it "should return list of server." do
    uri = 'druby://:13001'
    h = { :pid => 1234 }
    subject.save(uri, h)
    list = subject.list
    list.should be_an_instance_of Hash
    list[uri].should == h
  end

  it "should delete." do
    uri = 'druby://:13002'
    h = { :pid => 2222 }
    subject.save(uri, h)
    subject.delete(uri)
    subject.get(uri).should be_nil
  end

  it "should get from uri." do
    h = { :pid => 1111 }
    subject.save('druby://:13003', h)
    subject.get('druby://example.com:13003').should == h
  end

  it "should have server of key." do
    subject.save('druby://:13004',  { :key => 'key1' })
    subject.server_of_key_exist?('druby://example.com:13004', 'key1').should be_true
  end

  it "should not have server of key." do
    subject.save('druby://:13005',  { :key => 'key2' })
    subject.server_of_key_exist?('druby://example.com:13005', 'invalid_key').should be_false
  end

  it "should not have server." do
    subject.delete('druby://:13005')
    subject.server_of_key_exist?('druby://example.com:13006', 'key').should be_false
  end

  after(:all) do
    FileUtils.rm_r(@dir)
  end

end

describe DRbQS::ProcessList::Node do
  before(:all) do
    @dir = File.join(File.dirname(__FILE__), 'tmp_process_list/node')
    FileUtils.mkdir_p(@dir)
  end

  subject do
    DRbQS::ProcessList::Node.new(@dir)
  end

  it "should save data" do
    pid = 10000
    h = { :uri => 'druby://:13000' }
    subject.save(pid, h)
    subject.get(pid).should == h
  end

  it "should return list of server." do
    pid = 10001
    h = { :uri => 'druby://:13001' }
    subject.save(pid, h)
    list = subject.list
    list.should be_an_instance_of Hash
    list[pid].should == h
  end

  it "should delete." do
    pid = 10002
    h = { :uri => 'druby://:13002' }
    subject.save(pid, h)
    subject.delete(pid)
    subject.get(pid).should be_nil
  end

  after(:all) do
    FileUtils.rm_r(@dir)
  end

end

describe DRbQS::ProcessList do
  before(:all) do
    @dir = File.join(File.dirname(__FILE__), 'tmp_process_list')
    FileUtils.mkdir_p(@dir)
  end

  subject do
    DRbQS::ProcessList.new(@dir)
  end

  it "should create directory." do
    subject
    File.exist?(File.join(@dir, 'process')).should be_true
    File.exist?(File.join(@dir, 'process/server')).should be_true
    File.exist?(File.join(@dir, 'process/node')).should be_true
  end

  after(:all) do
    FileUtils.rm_r(@dir)
  end

end
