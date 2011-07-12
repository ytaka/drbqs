require 'user_config'
require 'drbqs/config/process_list'

module DRbQS

  ACL_DEFAULT_PATH = 'acl.txt'
  ACL_SAMPLE_PATH = 'acl.txt.sample'
  HOST_FILE_DIRECTORY = 'host'
  HOST_FILE_SAMPLE_PATH = 'host.yaml.sample'
  SHELL_FILE_DIRECTORY = 'shell'
  SHELL_BASHRC = 'bashrc'

  class ConfigDirectory < UserConfig
  end

  class Config
    DRBQS_CONFIG_DIRECTORY = '.drbqs'

    @@home_directory = nil

    def self.set_home_directory(path)
      @@home_directory = File.expand_path(path)
    end

    def self.get_home_directory
      @@home_directory || ENV['HOME']
    end

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

    attr_reader :directory, :list

    def initialize
      home = self.class.get_home_directory
      @directory = DRbQS::ConfigDirectory.new(DRBQS_CONFIG_DIRECTORY, :home => home)
      @list = DRbQS::ProcessList.new(File.join(home, DRBQS_CONFIG_DIRECTORY))
    end

    def directory_path
      @directory.directory
    end

    def save_sample
      @directory.open(ACL_SAMPLE_PATH, 'w') do |f|
        f.print ACL_SAMPLE
      end
      @directory.open(File.join(HOST_FILE_DIRECTORY, HOST_FILE_SAMPLE_PATH), 'w') do |f|
        f.print HOST_YAML_SAMPLE
      end
      @directory.open(File.join(SHELL_FILE_DIRECTORY, SHELL_BASHRC), 'w') do |f|
        f.print BASHRC_SAMPLE
      end
    end

    # Return path of ACL file if '.drbqs/acl.txt' exists.
    def get_acl_file
      @directory.exist?(ACL_DEFAULT_PATH)
    end

    def get_host_file_directory
      @directory.file_path(HOST_FILE_DIRECTORY)
    end

    def get_shell_file_directory
      @directory.file_path(SHELL_FILE_DIRECTORY)
    end

  end

end
