require 'fileutils'
require 'singleton'

module DRbQS

  class Config

    @@data = {
      :dir => ENV['HOME'] + '/.drbqs/'
    }

    class << self
      def set_directory(dir)
        @@data[:dir] = dir
      end

      def check_directory_create
        unless File.exist?(@@data[:dir])
          FileUtils.mkdir_p(@@data[:dir])
          FileUtils.chmod(0700, @@data[:dir])
        end
      end

      def get_acl_file
        path = File.join(@@data[:dir], 'acl.txt')
        if File.exist?(path)
          return path
        end
        return nil
      end
    end
  end

end
