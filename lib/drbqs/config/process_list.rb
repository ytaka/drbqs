require 'yaml'

module DRbQS
  class ProcessList
    PROCESS_ROOT_DIRECTORY = 'process'
    SERVER_DIRECTORY = 'server'
    NODE_DIRECTORY = 'node'

    class ListDirectory
      def initialize(dir)
        @directory = dir
        FileUtils.mkdir_p(@directory) unless File.exist?(@directory)
      end

      def path_under_directory(file)
        File.join(@directory, file)
      end
      private :path_under_directory

      # If +file+ exists then this method returns false.
      # Otherwise, return true.
      def save_file(file, data)
        path = path_under_directory(file)
        if File.exist?(path)
          false
        else
          open(path, 'w') do |f|
            f.print data.to_yaml
          end
          true
        end
      end
      private :save_file

      # If +file+ does not exist then this method returns nil.
      def load_file(file)
        path = path_under_directory(file)
        if File.exist?(path)
          YAML.load_file(path)
        else
          nil
        end
      end
      private :load_file

      def delete_file(file)
        path = path_under_directory(file)
        FileUtils.remove(path) if File.exist?(path)
      end
      private :delete_file

      def entries
        Dir.entries(@directory).delete_if do |dir|
          /^\.+$/ =~ dir
        end
      end
      private :entries
    end

    class Server < ListDirectory
      def uri_to_file(uri)
        case uri
        when /^druby.*:(\d+)$/
          "druby_#{Regexp.last_match[1]}.yaml"
        when /^drbunix:(.*)$/
          "drbunix#{Regexp.last_match[1].gsub(/\//, '_')}.yaml"
        else
          raise ArgumentError, "Invalid uri of drbqs server: #{uri}"
        end
      end
      private :uri_to_file

      def file_to_uri(file)
        s = file.sub(/\.yaml$/, '')
        case s
        when /^druby/
          s.sub(/_/, '://:')
        when /^drbunix$/
          s.gsub(/_/, '/')
        else
          raise ArgumentError, "Invalid file name in process list: #{file}"
        end
      end
      private :file_to_uri

      def list
        h = {}
        entries.each do |file|
          h[file_to_uri(file)] = load_file(file)
        end
        h
      end

      # If file exists then this method overwrites the file.
      def save(uri, data)
        unless save_file(uri_to_file(uri), data)
          delete(uri)
          save(uri, data)
        end
      end

      def get(uri)
        load_file(uri_to_file(uri))
      end

      def delete(uri)
        delete_file(uri_to_file(uri))
      end
    end

    class Node < ListDirectory
      def pid_to_file(pid)
        sprintf("%010d.yaml", pid)
      end
      private :pid_to_file

      def file_to_pid(file)
        file.sub(/\.yaml$/, '').to_i
      end
      private :file_to_pid

      def list
        h = {}
        entries.each do |file|
          h[file_to_pid(file)] = load_file(file)
        end
        h
      end

      # If file exists then this method overwrites the file.
      def save(pid, data)
        unless save_file(pid_to_file(pid), data)
          delete(pid)
          save(pid, data)
        end
      end

      def get(pid)
        load_file(pid_to_file(pid))
      end

      def delete(pid)
        delete_file(pid_to_file(pid))
      end
    end

    attr_reader :root, :server, :node

    def initialize(home)
      @root = File.expand_path(File.join(home, PROCESS_ROOT_DIRECTORY))
      @server = DRbQS::ProcessList::Server.new(File.join(@root, SERVER_DIRECTORY))
      @node = DRbQS::ProcessList::Node.new(File.join(@root, NODE_DIRECTORY))
    end
  end
end
