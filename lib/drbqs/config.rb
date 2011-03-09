require 'fileutils'
require 'singleton'

module DRbQS

  class Config

    @@data = {
      :dir => ENV['HOME'] + '/.drbqs/'
    }

    ACL_SAMPLE =<<SAMPLE
deny all
allow localhost
allow 127.0.0.1
SAMPLE

    class << self
      def get_path(name)
        File.join(@@data[:dir], name)
      end
      private :get_path

      def set_directory(dir)
        @@data[:dir] = dir
      end

      def check_directory_create
        unless File.exist?(@@data[:dir])
          FileUtils.mkdir_p(@@data[:dir])
          FileUtils.chmod(0700, @@data[:dir])
        end
      end

      def save_sample
        path = get_path('acl.txt.sample')
        unless File.exist?(path)
          open(path, 'w') { |f| f.print ACL_SAMPLE }
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
