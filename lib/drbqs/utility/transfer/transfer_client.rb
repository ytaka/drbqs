require 'drbqs/utility/transfer/transfer_client_connect.rb'

module DRbQS
  class Transfer
    class Client
      attr_reader :directory, :local, :sftp

      def initialize(server_directory, same_host, host, user)
        unless Pathname.new(server_directory).absolute?
          raise ArgumentError, "Directory of server must be absolute."
        end
        @directory = server_directory
        @same_host = same_host
        @local = DRbQS::Transfer::Client::Local.new(@directory)
        if host && user
          @sftp = DRbQS::Transfer::Client::SFTP.new(user, host, @directory)
        else
          @sftp = nil
        end
      end

      def transfer(files)
        transfered = false
        if @same_host
          begin
            @local.transfer(files)
            transfered = true
          rescue
          end
        end
        if !transfered
          unless @sftp
            raise "Can not transfer files."
          end
          @sftp.transfer(files)
        end
      end

      def download(files, readonly = nil)
        download_files = nil
        if @same_host
          begin
            if readonly
              download_files = files
            else
              download_files = @local.download(files)
            end
          rescue
          end
        end
        if !download_files
          unless @sftp
            raise "SFTP is not prepared."
          end
          download_files = @sftp.download(files)
        end
        download_files
      end

      class << self
        @transfer = nil

        def get
          @transfer
        end

        def set(transfer)
          @transfer = transfer
        end

        def transfer_to_server(files)
          if files && @transfer
            begin
              @transfer.transfer(files)
            rescue Exception => err
              err_new = err.class.new("#{err.to_s} (#{err.class}); Can not send file: #{files.join(", ")}")
              err_new.set_backtrace(err.backtrace)
              raise err_new
            end
          else
            raise "Server does not set transfer settings. Can not send file: #{files.join(", ")}"
          end
        end
      end
    end
  end
end
