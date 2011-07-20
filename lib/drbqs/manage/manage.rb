require 'forwardable'
require 'drbqs/manage/ssh_execute'
require 'drbqs/manage/send_signal'

module DRbQS
  class Manage
    extend Forwardable

    class NotSetURI < StandardError
    end

    WAIT_SERVER_TIME = 0.3
    WAIT_MAX_NUMBER = 200

    # +opts+ has keys :home and :uri.
    def initialize(opts = {})
      @opts = opts
      @config = nil
      @signal_sender = nil
    end

    def set_uri(uri)
      @opts[:uri] = uri
    end

    def set_home_directory(dir)
      @opts[:home] = dir
    end

    def config
      unless @config
        if @opts[:home]
          DRbQS::Config.set_home_directory(@opts[:home])
        end
        @config = DRbQS::Config.new
      end
      @config
    end
    private :config

    def signal_sender
      unless @signal_sender
        unless @opts[:uri]
          raise DRbQS::Manage::NotSetURI, "The uri has not set yet."
        end
        obj = DRbObject.new_with_uri(@opts[:uri])
        @signal_sender = DRbQS::Manage::SendSignal.new(obj[:message])
      end
      @signal_sender
    end
    private :signal_sender

    def create_config
      config.save_sample
    end

    [:get_status, :get_history, :send_exit_signal, :send_node_exit_after_task,
     :send_node_wake, :send_node_sleep].each do |method_name|
      def_delegator :signal_sender, method_name, method_name
    end

    def server_respond?
      begin
        get_status
        true
      rescue DRbQS::Manage::NotSetURI
        raise
      rescue
        nil
      end
    end

    def wait_server_process(pid)
      i = 0
      begin
        sleep(WAIT_SERVER_TIME)
        unless DRbQS::Misc.process_running_normally?(pid)
          return nil
        end
        i += 1
        if i > WAIT_MAX_NUMBER
          raise "Can not wait server process."
        end
      end while !server_respond?
      true
    end

    def list_process
      { :server => config.list.server.list, :node => config.list.node.list }
    end

    def clear_process
      config.list.clear_process_not_exist
    end
  end
end
