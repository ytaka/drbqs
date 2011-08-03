require 'tmpdir'

module DRbQS
  module Temporary
    @@root = nil
    @@filename = nil

    # Return FileName object to generate names of temporary files on DRbQS nodes.
    def self.filename
      unless @@filename
        pid = Process.pid
        @@root = File.join(Dir.tmpdir, sprintf("drbqs_%d_%d", pid, rand(10000)))
        FileUtils.mkdir_p(@@root, :mode => 0700)
        @@filename = FileName.new(File.join(@@root, sprintf("temp_%d_%d", pid, rand(10000))))
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
        filename.create(:add => :always)
      end
    end

    # Make root of temporary directory empty.
    def self.delete
      if @@root
        FileUtils.rm_r(@@root)
        FileUtils.mkdir_p(@@root)
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
  end
end
