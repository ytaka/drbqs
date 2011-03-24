require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'drbqs/node_list'

describe DRbQS::NodeList do
  before(:all) do
    @node_list = DRbQS::NodeList.new
    @id_strings = 10.times.map { |i| sprintf("%05d", i) }
    @id_list = []
  end

  it "should be empty." do
    @node_list.empty?.should be_true
  end

  it "should get ids that are not duplicated." do
    @id_strings.each do |str|
      @id_list << @node_list.get_new_id(str)
    end
    @id_list.uniq!
    @id_list.all? { |i| Integer === i }.should be_true
    @id_list.size.should == @id_strings.size
    @node_list.each do |id_num, id_str|
      @id_strings.include?(id_str).should be_true
      @id_list.include?(id_num).should be_true
    end
  end

  it "should delete all ids" do
    @node_list.empty?.should_not be_true
    @node_list.set_check_connection
    ids = @node_list.delete_not_alive
    ids.sort.should == @id_list.sort
    @node_list.empty?.should be_true
    @id_list.clear
  end

  it "should set alive flag" do
    alive_id_num = [3, 4, 5]
    @id_strings.each do |str|
      @id_list << @node_list.get_new_id(str)
    end
    @node_list.set_check_connection
    alive_id_num.each do |i|
      @node_list.set_alive(@id_list[i])
    end
    @node_list.delete_not_alive
    alive_ids = alive_id_num.map { |i| @id_list[i] }
    @node_list.each do |id_num, id_str|
      alive_ids.include?(id_num).should be_true
    end
  end

  it "should add to history" do
    node_list = DRbQS::NodeList.new
    node_list.history.should_receive(:begin)
    node_list.get_new_id('hello')
  end

  it "should set disconnection to history" do
    node_list = DRbQS::NodeList.new
    node_list.history.should_receive(:finish)
    node_list.get_new_id('hello')
    node_list.set_check_connection
    node_list.delete_not_alive
  end

end
