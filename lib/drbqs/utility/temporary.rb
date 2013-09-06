require 'tmpdir'

module DRbQS
  module Temporary
    @root = nil
    @pid = nil
    @subdir = nil
    @filename = nil

    # Return root of temporary directory.
    def self.root
      if @pid != Process.pid
        @pid = Process.pid
        @root = File.join(Dir.tmpdir, sprintf("drbqs_%s_%d_%d", ENV['USER'], @pid, rand(10000)))
        FileUtils.mkdir_p(@root, :mode => 0700)
      end
      @root
    end

    def self.set_sub_directory(dir)
      @filename = nil
      @subdir = File.join(self.root, dir)
    end

    def self.subdirectory
      @subdir && File.exist?(@subdir) ? @subdir : nil
    end

    # Return FileName object to generate names of temporary files on DRbQS nodes.
    def self.filename
      unless @filename
        if @subdir
          @filename = FileName.new(File.join(@subdir, sprintf("temp_%d", rand(10000))))
        else
          @filename = FileName.new(File.join(self.root, sprintf("temp_%d", rand(10000))))
        end
      end
      @filename
    end

    # Create new temporary directory and return the path of directory.
    def self.directory
      filename.create(:add => :always, :directory => :self)
    end

    # Return new path of temporary file.
    # @param [String] basename Set the basename of created filename
    def self.file(basename = nil)
      if basename
        File.join(self.directory, basename)
      else
        filename.create(:add => :always, :directory => :parent)
      end
    end

    # Delete all temporary directory.
    def self.delete
      if @root
        FileUtils.rm_r(@root)
        @pid = nil
        @root = nil
        @filename = nil
      end
    end

    def self.socket_path
      FileName.create(self.root, "socket", :add => :always, :type => :time)
    end
  end
end
