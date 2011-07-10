module DRbQS
  module Temporary
    @@root = nil
    @@filename = nil

    def self.filename
      unless @@filename
        @@root = sprintf("/tmp/drbqs_%d_%d", Process.pid, rand(10000))
        FileUtils.mkdir_p(@@root)
        @@filename = FileName.new(File.join(@@root, 'temp'))
      end
      @@filename
    end

    # Create new temporary directory and return the path of directory.
    def self.directory
      filename.create(:add => :always, :directory => :self)
    end

    # Return new path of temporary file.
    def self.file
      filename.create(:add => :always)
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

    def self.root
      @@root
    end
  end
end
