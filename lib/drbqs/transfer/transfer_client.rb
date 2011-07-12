require 'net/sftp'

module DRbQS

  class TransferClient

    # Transfer files to directory on DRbQS server.
    # In this class we use scp command.
    # Note that after we transfer files we delete the files.
    class SFTP
      attr_reader :user, :host, :directory

      def initialize(user, host, directory)
        @user = user
        @host = host
        @directory = File.expand_path(directory)
      end

      def upload_name(path)
        File.join(@directory, File.basename(path))
      end
      private :upload_name

      # Transfer and delete +files+.
      def transfer(files)
        Net::SFTP.start(@host, @user) do |sftp|
          files.each do |path|
            sftp.upload(path, upload_name(path))
            FileUtils.rm_r(path)
          end
        end
        true
      end
    end

    class Local
      def initialize(directory)
        @directory = File.expand_path(directory)
      end

      def upload_name(path)
        File.join(@directory, File.basename(path))
      end
      private :upload_name

      def transfer(files)
        files.each do |path|
          FileUtils.mv(path, upload_name(path))
        end
        true
      end
    end

    attr_reader :directory, :local, :sftp

    def initialize(dir)
      @directory = dir
      @local = DRbQS::TransferClient::Local.new(@directory)
      @sftp = nil
    end

    def make_directory
      FileUtils.mkdir_p(@directory)
    end

    def set_sftp(user, host)
      @sftp = DRbQS::TransferClient::SFTP.new(user, host, @directory)
    end

    def information
      info = "directory: #{@directory}"
      info << ", sftp: #{@sftp.user}@#{@sftp.host}" if @sftp
      info
    end
  end

end
