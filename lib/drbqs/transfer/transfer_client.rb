require 'net/sftp'

module DRbQS

  module TransferClient

    # Transfer files to directory on DRbQS server.
    # In this class we use scp command.
    # Note that after we transfer files we delete the files.
    class SFTP
      attr_reader :user, :host, :directory

      def initialize(user, host, directory)
        @user = user
        @host = host
        @directory = File.expand_path(directory)
        FileUtils.mkdir_p(@directory)
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

      def information
        "#{@user}@#{@host} #{@directory}"
      end
    end

    class Local
      def initialize(directory)
        @directory = File.expand_path(directory)
        FileUtils.mkdir_p(@directory)
      end

      def transfer(files)
        files.each do |path|
          FileUtils.mv(path, upload_name(path))
        end
        true
      end

      def information
        @directory
      end
    end
  end

end
