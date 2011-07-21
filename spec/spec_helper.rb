$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'drbqs'
require 'drbqs/manage/manage'

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

def drbqs_wait_kill_server(process_id, wait_time = 10)
  i = 0
  while !Process.waitpid(process_id, Process::WNOHANG)
    i += 1
    if i > wait_time
      Process.kill(:KILL, process_id)
      raise "Server process does not finish."
    end
    sleep(1)
  end
end

def drbqs_fork_server(uri_arg, task_args, opts = {})
  server_args = opts[:opts] || {}
  if Integer === uri_arg
    server_args[:port] = uri_arg
    uri = "druby://:#{uri_arg}"
  else
    server_args[:unix] = uri_arg
    uri = "drbunix:#{uri_arg}"
  end
    
  pid = fork do
    server = DRbQS::Server.new(server_args)

    unless task_args.respond_to?(:each)
      task_args = [task_args]
    end
    task_args.each do |arg|
      if DRbQS::TaskGenerator === arg
        server.add_task_generator(arg)
      else
        server.queue.add(arg)
      end
    end

    unless opts[:continue]
      server.add_hook(:finish) do |serv|
        serv.exit
      end
    end

    server.set_signal_trap
    server.start
    server.wait
  end
  sleep(opts[:sleep] || 1)
  [pid, uri]
end
