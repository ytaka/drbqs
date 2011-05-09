$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'drbqs'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  
end

def drbqs_test_tuple_space(uri)
  ts = {
    :message => Rinda::TupleSpace.new,
    :queue => Rinda::TupleSpace.new,
    :result => Rinda::TupleSpace.new,
    :transfer => nil
  }
  DRb.start_service(uri, ts)
  ts
end
