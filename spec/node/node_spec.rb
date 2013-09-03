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
      node_number = 10
      DRb::DRbObject.should_receive(:new_with_uri).and_return(@drb_object)
      node_connection = double('node connection')
      node_connection.stub(:node_number).and_return(node_number)
      node_connection.stub(:get_initialization).and_return(nil)
      task_client = double('task client')
      task_client.stub(:node_number).and_return(node_number)
      worker = double('worker')
      worker.stub(:create_process)
      worker.stub(:on_error)
      worker.stub(:on_result)
      DRbQS::Node::Connection.should_receive(:new).and_return(node_connection)
      DRbQS::Node::TaskClient.should_receive(:new).and_return(task_client)
      DRbQS::Worker::ProcessSet.should_receive(:new).and_return(worker)
      subject.connect
    end
  end
end
