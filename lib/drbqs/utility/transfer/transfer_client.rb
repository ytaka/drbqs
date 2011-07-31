require 'net/sftp'

module DRbQS
  class Transfer
    class Client
      class ClientBase
        def initialize(server_directory)
          @directory = server_directory
        end

        def upload_name(path)
          File.join(@directory, File.basename(path))
        end
        private :upload_name
      end

      # Transfer files to directory on DRbQS server over sftp.
      # Note that after we transfer files we delete the original files.
      class SFTP < DRbQS::Transfer::Client::ClientBase
        attr_reader :user, :host, :directory

        def initialize(user, host, directory)
          super(directory)
          @user = user
          @host = host
        end

        # Transfer and delete +files+.
        def transfer(files)
          Net::SFTP.start(@host, @user) do |sftp|
            files.each do |path|
              sftp.upload(path, upload_name(path))
              FileUtils.rm_r(path)
            end
          end
        rescue => err
          raise err.class, "user=#{@user}, host=#{@host}, directory=#{@directory}; #{err.to_s}", err.backtrace 
        end
      end

      class Local < DRbQS::Transfer::Client::ClientBase
        def transfer(files)
          files.each do |path|
            FileUtils.mv(path, upload_name(path))
          end
        end
      end

      attr_reader :directory, :local, :sftp

      def initialize(server_directory)
        unless Pathname.new(server_directory).absolute?
          raise ArgumentError, "Directory of server must be absolute."
        end
        @directory = server_directory
        @local = DRbQS::Transfer::Client::Local.new(@directory)
        @sftp = nil
      end

      def set_sftp(user, host)
        @sftp = DRbQS::Transfer::Client::SFTP.new(user, host, @directory)
      end

      def information
        info = "directory: #{@directory}"
        info << ", sftp: #{@sftp.user}@#{@sftp.host}" if @sftp
        info
      end

      def transfer(files, on_same_host = nil)
        transfered = false
        if on_same_host
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
    end
  end
end
