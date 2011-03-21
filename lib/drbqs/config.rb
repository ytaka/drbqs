require 'fileutils'
require 'singleton'

module DRbQS

  ACL_DEFAULT_PATH = 'acl.txt'
  ACL_SAMPLE_PATH = 'acl.txt.sample'
  HOST_FILE_DIRECTORY = 'host'

  class Config

    @@data = {
      :dir => ENV['HOME'] + '/.drbqs/',
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

      def get_host_file_directory
        get_path(HOST_FILE_DIRECTORY)
      end

      def check_directory_create
        unless File.exist?(@@data[:dir])
          FileUtils.mkdir_p(@@data[:dir])
          FileUtils.chmod(0700, @@data[:dir])
        end
        host = get_host_file_directory
        unless File.exist?(host)
          FileUtils.mkdir_p(host)
        end
      end

      def save_sample
        path = get_path(ACL_SAMPLE_PATH)
        unless File.exist?(path)
          open(path, 'w') { |f| f.print ACL_SAMPLE }
        end
      end

      def get_acl_file
        path = File.join(@@data[:dir], ACL_DEFAULT_PATH)
        if File.exist?(path)
          return path
        end
        return nil
      end
    end
  end

end
