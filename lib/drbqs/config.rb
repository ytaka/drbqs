require 'singleton'

module DRbQS

  ACL_DEFAULT_PATH = 'acl.txt'
  ACL_SAMPLE_PATH = 'acl.txt.sample'
  HOST_FILE_DIRECTORY = 'host'
  HOST_FILE_SAMPLE_PATH = 'host.yaml.sample'
  SHELL_FILE_DIRECTORY = 'shell'
  SHELL_BASHRC = 'bashrc'

  class Config

    @@data = {
      :dir => ENV['HOME'] + '/.drbqs/',
    }

    ACL_SAMPLE =<<SAMPLE
deny all
allow localhost
allow 127.0.0.1
SAMPLE

    HOST_YAML_SAMPLE =<<SAMPLE
--- 
:dest: user@example.com
:dir:
:shell: bash --noprofile --init-file ~/.drbqs/shell/bashrc
:rvm:
:rvm_init: ~/.rvm/scripts/rvm
:output: 
SAMPLE

    BASHRC_SAMPLE = <<SAMPLE
HISTFILE=$HOME/.drbqs/shell/bash_history
HISTSIZE=10000
HISTFILESIZE=20000
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

      def get_shell_file_directory
        get_path(SHELL_FILE_DIRECTORY)
      end

      def make_directory(dir)
        unless File.exist?(dir)
          FileUtils.mkdir_p(dir)
        end
      end
      private :make_directory

      def check_directory_create
        unless File.exist?(@@data[:dir])
          FileUtils.mkdir_p(@@data[:dir])
          FileUtils.chmod(0700, @@data[:dir])
        end
        [get_host_file_directory, get_shell_file_directory].each do |dir|
          make_directory(dir)
        end
      end

      def output_to_file(path, content)
        unless File.exist?(path)
          open(path, 'w') { |f| f.print content }
        end
      end
      private :output_to_file

      def save_sample
        output_to_file(get_path(ACL_SAMPLE_PATH), ACL_SAMPLE)
        output_to_file("#{get_host_file_directory}/#{HOST_FILE_SAMPLE_PATH}", HOST_YAML_SAMPLE)
        output_to_file("#{get_shell_file_directory}/#{SHELL_BASHRC}", BASHRC_SAMPLE)
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
