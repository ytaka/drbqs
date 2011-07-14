require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/server/node_list'

describe DRbQS::Server::NodeList do
  before(:all) do
    @count = 0
  end

  subject do
    DRbQS::Server::NodeList.new
  end

  def create_id_string
    sprintf("ID_%05d", (@count += 1))
  end

  context "when checking nodes" do
    it "should be empty." do
      subject.empty?.should be_true
    end

    it "should not be empty." do
      subject.get_new_id(create_id_string)
      subject.empty?.should_not be_true
    end

    it "should return true for existence of node id" do
      id = subject.get_new_id(create_id_string)
      subject.exist?(id).should be_true
    end

    it "should not return true for nonexistent node id" do
      subject.exist?(-100).should_not be_true
    end
  end

  context "when managing nodes" do
    it "should get ids that are not duplicated." do
      id_strings = 10.times.map do |i|
        create_id_string
      end.uniq
      id_nums = id_strings.map do |str|
        subject.get_new_id(str)
      end
      id_nums.should have(id_strings.size).items
    end

    it "should yield each nodes." do
      id_data = 10.times.map do |i|
        id_str = create_id_string
        [id_str, subject.get_new_id(id_str)]
      end
      subject.each do |id_num, id_str|
        id_data.assoc(id_str)[1].should == id_num
      end
    end

    it "should delete a node" do
      id = subject.get_new_id(create_id_string)
      subject.delete(id)
      subject.exist?(id).should_not be_true
    end
  end

  context "when setting alive checkings" do
    it "should delete all ids" do
      5.times do |i|
        subject.get_new_id(create_id_string)
      end
      subject.set_check_connection
      subject.delete_not_alive
      subject.empty?.should be_true
    end

    it "should set alive flag" do
      delete_ids = 3.times.map do |i|
        subject.get_new_id(create_id_string)
      end
      alive_ids = 3.times.map do |i|
        subject.get_new_id(create_id_string)
      end
      subject.set_check_connection
      alive_ids.each do |id|
        subject.set_alive(id)
      end
      subject.delete_not_alive
      alive_ids.all? do |id|
        subject.exist?(id)
      end.should be_true
      delete_ids.all? do |id|
        !subject.exist?(id)
      end.should be_true
    end
  end

  context "when managing history" do
    it "should add to history" do
      subject.history.should_receive(:set).with(1, :connect, 'hello')
      subject.get_new_id('hello')
    end

    it "should set disconnection to history" do
      subject.get_new_id('hello')
      subject.set_check_connection
      subject.history.should_receive(:set).with(1, :disconnect)
      subject.delete_not_alive
    end
  end

end
