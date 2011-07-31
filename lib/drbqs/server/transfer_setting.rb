require 'drbqs/utility/transfer/transfer_client'

module DRbQS
  class Server
    class TransferSetting
      attr_accessor :host, :user, :directory

      def initialize(host, user, directory)
        @host = host
        @user = user
        @directory = directory
        @created = false
      end

      def create(directory, opts = {})
        return nil if @created
        @directory = directory || @directory
        return nil if !@directory
        @created = true
        dir = File.expand_path(@directory)
        transfer_client = DRbQS::Transfer::Client.new(dir)
        FileUtils.mkdir_p(dir)
        if host = opts[:host] || @host
          user = opts[:user] || @user || ENV['USER']
          transfer_client.set_sftp(user, host)
        end
        transfer_client
      end
    end
  end
end
