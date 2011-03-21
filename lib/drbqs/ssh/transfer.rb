require 'fileutils'
require 'zlib'

module DRbQS

  # Transfer files to directory on DRbQS server.
  # In this class we use scp command.
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
      system("scp #{path} #{@user}@#{@host}:#{File.join(@directory, name)} > /dev/null 2>&1")
    end
  end

  # To compress files, we use gzip command.
  module FileTransfer
    @@files = Queue.new

    def self.enqueue(path)
      @@files.enq(path)
    end

    def self.compress_enqueue(path)
      gz_path = path + '.gz'
      Zlib::GzipWriter.open(gz_path, Zlib::BEST_COMPRESSION) do |gz|
        gz.mtime = File.mtime(path)
        gz.orig_name = path
        gz.print File.open(path, 'rb'){ |f| f.read }
      end
      FileUtils.rm(path)
      self.enqueue(gz_path)
    end

    def self.dequeue
      @@files.deq
    end

    def self.empty?
      @@files.empty?
    end
  end
end
