require 'socket'

module DRbQS

  class SendCommand
    MAX_WAIT_TIME = 10

    def initialize(message)
      @message = message
    end

    def get_hostname
      "Command of #{Socket.gethostname}"
    end
    private :get_hostname

    def send_exit_signal
      @message.write([:server, :exit_server, get_hostname])
    end

    def get_status
      @message.write([:server, :request_status, get_hostname])
      i = 0
      loop do
        begin
          mes = @message.take([:status, String], 0)
          return mes[1]
        rescue Rinda::RequestExpiredError
          i += 1
          if i > MAX_WAIT_TIME
            return nil
          end
          sleep(1)
        end
      end
    end
  end

  class Manage
    def self.split_arguments(argv, split = '--')
      if n = argv.index(split)
        [argv[0..(n - 1)], argv[(n + 1)..-1]]
      else
        [argv, []]
      end
    end

    def create_config
      Config.check_directory_create
      Config.save_sample
    end

    def command_client(access_uri)
      obj = DRbObject.new_with_uri(access_uri)
      DRbQS::SendCommand.new(obj[:message])
    end
    private :command_client

    def send_exit_signal(access_uri)
      command_client(access_uri).send_exit_signal
    end

    def get_status(access_uri)
      command_client(access_uri).get_status
    end

    def execute_over_ssh(dest, opts, command)
      ssh = DRbQS::SSHShell.new(dest, opts)
      ssh.start(command)
    end

    def get_ssh_environment(dest, opts)
      ssh = DRbQS::SSHShell.new(dest, opts)
      ssh.get_environment
    end
  end
end
