require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DRbQS::Node do
  context "when starting node" do
    def init_node_objects(object = {})
      @uri = 'drbunix:/tmp/drb_test'
      @drb_object = {
        :message => Rinda::TupleSpace.new,
        :queue => Rinda::TupleSpace.new,
        :result => Rinda::TupleSpace.new,
        :key => 'server_key',
        :transfer => nil
      }.merge(object)
    end

    subject do
      DRbQS::Node.new(@uri, :log_file => STDOUT)
    end

    before(:all) do
      init_node_objects
    end

    it "should connect to server." do
      DRb::DRbObject.should_receive(:new_with_uri).and_return(@drb_object)
      node_connection = mock('node connection')
      node_connection.stub(:node_number).and_return(10)
      node_connection.stub(:get_initialization).and_return(nil)
      DRbQS::Node::Connection.should_receive(:new).and_return(node_connection)
      DRbQS::Node::TaskClient.should_receive(:new)
      subject.connect
    end
  end
end
