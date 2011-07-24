require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/server/test/server'
require_relative 'definition/task_obj_definition.rb'

describe DRbQS::Test::Server do
  it "should execute as test." do
    DRbQS.define_server do |server, argv, opts|
      5.times do |i|
        server.queue.add(DRbQS::Task.new(TestCount.new, :calc))
      end
    end
    server = DRbQS.create_test_server({})
    data = server.test_exec
    data.should be_an_instance_of Hash
    TestCount.get.should == 5
  end
end
