require 'net/sftp'

module DRbQS

  module Transfer

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

  # To compress files, we use gzip and tar command.
  # Note that if we compress files then we delete the source files.
  module FileTransfer
    @@files = Queue.new

    # If opts[:compress] is true then the file of +path+ is compressed before tranfering.
    def self.enqueue(path, opts = {})
      if opts[:rename]
        new_path = FileName.create(File.join(File.dirname(path), opts[:rename]), :directory => :parent)
        FileUtils.mv(path, new_path)
        path = new_path
      end
      if opts[:compress]
        if File.directory?(path)
          gz_path = "#{path.sub(/\/$/, '')}.tar.gz"
          cmd = "tar czf #{gz_path} -C #{File.dirname(path)} #{File.basename(path)} > /dev/null 2>&1"
        else
          gz_path = path + '.gz'
          cmd = "gzip --best #{path} > /dev/null 2>&1"
        end
        if File.exist?(gz_path)
          raise "File has already existed: #{gz_path}"
        elsif !system(cmd)
          raise "Can not compress: #{path}"
        end
        FileUtils.rm_r(path) if File.exist?(path)
        path_to_send = gz_path
      else
        path_to_send = path
      end
      @@files.enq(path_to_send)
      File.basename(path_to_send)
    end

    def self.compress_enqueue(path)
      self.enqueue(path, :compress => true)
    end

    def self.dequeue
      @@files.deq
    end

    def self.empty?
      @@files.empty?
    end

    def self.decompress(server, filename)
      dir = server.transfer_directory
      path = File.join(dir, filename)
      if File.exist?(path)
        case path
        when /\.tar\.gz$/
          cmd = "tar xvzf #{path} -C #{dir} > /dev/null 2>&1"
        when /\.gz$/
          cmd = "gunzip #{path} > /dev/null 2>&1"
        else
          cmd = nil
        end
        system(cmd) if cmd
      end
    end
  end
end
