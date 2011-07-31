require 'net/sftp'

module DRbQS
  class Transfer
    class Client
      class Base
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
      class SFTP < DRbQS::Transfer::Client::Base
        attr_reader :user, :host, :directory

        def initialize(user, host, directory)
          super(directory)
          @user = user
          @host = host
        end

        def start_sftp(&block)
          Net::SFTP.start(@host, @user, &block)
        end
        private :start_sftp

        # Transfer and delete +files+.
        def transfer(files)
          start_sftp do |sftp|
            files.each do |path|
              sftp.upload(path, upload_name(path))
              FileUtils.rm_r(path)
            end
          end
        rescue => err
          raise err.class, "user=#{@user}, host=#{@host}, directory=#{@directory}; #{err.to_s}", err.backtrace 
        end

        def download(files)
          moved = []
          start_sftp do |sftp|
            files.each do |path|
              dir = DRbQS::Temporary.directory
              sftp.download(path, dir, :recursive => true)
              moved << File.join(dir, File.basename(path))
            end
          end
          moved
        rescue => err
          raise err.class, "user=#{@user}, host=#{@host}, directory=#{@directory}; #{err.to_s}", err.backtrace 
        end
      end

      class Local < DRbQS::Transfer::Client::Base
        def transfer(files)
          files.each do |path|
            FileUtils.mv(path, upload_name(path))
          end
        end

        def download(files)
          files.map do |path|
            dir = DRbQS::Temporary.directory
            FileUtils.cp_r(path, dir)
            File.join(dir, File.basename(path))
          end
        end
      end
    end
  end
end
