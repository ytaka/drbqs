require 'tmpdir'

module DRbQS
  module Temporary
    @@root = nil
    @@subdir = nil
    @@filename = nil

    def self.set_root_directory
      if !@@root
        pid = Process.pid
        @@root = File.join(Dir.tmpdir, sprintf("drbqs_%s_%d_%d", ENV['USER'], pid, rand(10000)))
        FileUtils.mkdir_p(@@root, :mode => 0700)
      end
    end

    def self.set_sub_directory(dir)
      self.set_root_directory
      @@filename = nil
      @@subdir = File.join(@@root, dir)
    end

    def self.subdirectory
      @@subdir && File.exist?(@@subdir) ? @@subdir : nil
    end

    # Return FileName object to generate names of temporary files on DRbQS nodes.
    def self.filename
      unless @@filename
        self.set_root_directory
        if @@subdir
          @@filename = FileName.new(File.join(@@subdir, sprintf("temp_%d", rand(10000))))
        else
          @@filename = FileName.new(File.join(@@root, sprintf("temp_%d", rand(10000))))
        end
      end
      @@filename
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

    # Make root of temporary directory empty.
    def self.delete
      if @@root
        FileUtils.rm_r(@@root)
        FileUtils.mkdir_p(@@root, :mode => 0700)
      end
    end

    # Delete all temporary directory.
    def self.delete_all
      if @@root
        FileUtils.rm_r(@@root)
        @@root = nil
        @@filename = nil
      end
    end

    # Return root of temporary directory.
    def self.root
      @@root
    end

    def self.socket_path
      unless @@root
        set_root_directory
      end
      FileName.create(@@root, "socket", :add => :always, :type => :time)
    end
  end
end
