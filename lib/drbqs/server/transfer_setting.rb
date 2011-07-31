require 'drbqs/utility/transfer/transfer_client'

module DRbQS
  class Server
    class TransferSetting
      attr_accessor :host, :user, :directory

      def initialize(host, user, directory)
        @host = host
        @user = user
        @directory = directory
        @setup_server = false
      end

      def prepared_directory
        @setup_server && @directory
      end

      def information
        info = "directory: #{@directory}"
        info << ", sftp: #{@user}@#{@host}" if @host && @user
        info
      end

      def setup_server(directory, opts = {})
        return nil if @setup_server
        @directory = directory || @directory
        return nil if !@directory
        @setup_server = true
        @directory = File.expand_path(@directory)
        FileUtils.mkdir_p(@directory)
        @host = opts[:host] || @host
        @user = opts[:user] || @user || ENV['USER']
        true
      end

      def get_client(same_host)
        @setup_server ? DRbQS::Transfer::Client.new(@directory, same_host, @host, @user) : nil
      end
    end
  end
end
