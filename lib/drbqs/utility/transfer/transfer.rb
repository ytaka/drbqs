module DRbQS
  # To compress files, we use gzip and tar command.
  # Note that if we compress files then we delete the original files.
  class Transfer
    @files = Queue.new

    class << self
      # Add path to queue of which files is going to be transfered to server.
      # @param [String] path The file path that we want to send to a server.
      # @param [Hash] opts The options for transfering a file.
      # @option opts [Boolean] :compress Compress the file by gzip before transfering.
      # @option opts [String] :rename Change basename to the specified name.
      def enqueue(path, opts = {})
        if opts[:rename]
          new_path = FileName.create(File.join(File.dirname(path), opts[:rename]), :directory => :parent)
          FileUtils.mv(path, new_path)
          path = new_path
        end
        if opts[:compress]
          if File.directory?(path)
            gz_path = "#{path.sub(/\/$/, '')}.tar.gz"
            cmd = "tar czf #{gz_path} -C #{File.dirname(path)} #{File.basename(path)} > /dev/null 2>&1"
          else
            gz_path = path + '.gz'
            cmd = "gzip --best #{path} > /dev/null 2>&1"
          end
          if File.exist?(gz_path)
            raise "File has already existed: #{gz_path}"
          elsif !system(cmd)
            raise "Can not compress: #{path}"
          end
          FileUtils.rm_r(path) if File.exist?(path)
          path_to_send = gz_path
        else
          path_to_send = path
        end
        @files.enq(path_to_send)
        File.basename(path_to_send)
      end

      def compress_enqueue(path)
        enqueue(path, :compress => true)
      end

      def dequeue
        @files.deq
      end

      def empty?
        @files.empty?
      end

      def dequeue_all
        files = []
        until empty?
          files << dequeue
        end
        files.empty? ? nil : files
      end

      # Decompress a file in the file directory of a server.
      # @param [DRbQS::Server] server Current server
      # @param [String] filename File path to decompress
      def decompress(server, filename)
        dir = server.transfer_directory
        path = File.join(dir, filename)
        if File.exist?(path)
          case path
          when /\.tar\.gz$/
            cmd = "tar xvzf #{path} -C #{dir} > /dev/null 2>&1"
          when /\.gz$/
            cmd = "gunzip #{path} > /dev/null 2>&1"
          else
            cmd = nil
          end
          system(cmd) if cmd
        end
      end
    end
  end
end
