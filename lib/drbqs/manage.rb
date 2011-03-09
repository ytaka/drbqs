require 'socket'

module DRbQS

  class Manage
    def initialize(access_uri)
      @access_uri = access_uri
    end

    def create_config
      Config.check_directory_create
    end

    def send_exit_signal
      obj = DRbObject.new_with_uri(@access_uri)
      obj[:message].write([:exit_server, "Command of #{Socket.gethostname}"])
    end
  end
end
