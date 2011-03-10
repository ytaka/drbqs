require 'socket'

module DRbQS

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

    def send_exit_signal(access_uri)
      obj = DRbObject.new_with_uri(access_uri)
      obj[:message].write([:exit_server, "Command of #{Socket.gethostname}"])
    end
  end
end
