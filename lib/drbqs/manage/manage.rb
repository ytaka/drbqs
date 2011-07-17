require 'sys/proctable'
require 'drbqs/manage/ssh_execute'
require 'drbqs/manage/send_signal'

module DRbQS
  class Manage
    class NotSetURI < StandardError
    end

    WAIT_SERVER_TIME = 0.3

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

    def send_exit_signal
      signal_sender.send_exit_signal
    end

    def send_node_exit_after_task(node_id)
      signal_sender.send_node_exit_after_task(node_id)
    end

    def get_status
      signal_sender.get_status
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
      begin
        sleep(WAIT_SERVER_TIME)
        unless Sys::ProcTable.ps(pid)
          return nil
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
