require 'fileutils'

module DRbQS

  # Transfer files to directory on DRbQS server.
  # In this class we use scp command.
  # Note that after we transfer files we delete the files.
  class Transfer

    # options
    #   :mkdir    true or nil
    def initialize(user, host, directory)
      @user = user
      @host = host
      @directory = File.expand_path(directory)
      FileUtils.mkdir_p(@directory)
    end

    def scp(path)
      name = File.basename(path)
      unless File.exist?(path)
        raise ArgumentError, "File #{path} does not exist."
      end
      if system("scp -r #{path} #{@user}@#{@host}:#{File.join(@directory, name)} > /dev/null 2>&1")
        FileUtils.rm_r(path)
        return true
      end
      return false
    end
  end

  # To compress files, we use gzip and tar command.
  # Note that if we compress files then we delete the source files.
  module FileTransfer
    @@files = Queue.new

    def self.enqueue(path, compress = false)
      if compress
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
        @@files.enq(gz_path)
      else
        @@files.enq(path)
      end
    end

    def self.compress_enqueue(path)
      self.enqueue(path, true)
    end

    def self.dequeue
      @@files.deq
    end

    def self.empty?
      @@files.empty?
    end
  end
end
