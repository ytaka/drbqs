$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'drbqs'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  
end

HOME_FOR_SPEC = File.join(File.dirname(__FILE__), 'home_for_spec')

DRbQS::Config.set_home_directory(HOME_FOR_SPEC)

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

def drbqs_wait_kill_server(process_id)
  i = 0
  while !Process.waitpid(process_id, Process::WNOHANG)
    i += 1
    if i > 10
      Process.kill(:KILL, process_id)
      raise "Server process does not finish."
    end
    sleep(1)
  end
end
