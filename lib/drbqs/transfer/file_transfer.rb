module DRbQS
  # To compress files, we use gzip and tar command.
  # Note that if we compress files then we delete the source files.
  module FileTransfer
    @@files = Queue.new

    # If opts[:compress] is true then the file of +path+ is compressed before tranfering.
    def self.enqueue(path, opts = {})
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
      @@files.enq(path_to_send)
      File.basename(path_to_send)
    end

    def self.compress_enqueue(path)
      self.enqueue(path, :compress => true)
    end

    def self.dequeue
      @@files.deq
    end

    def self.empty?
      @@files.empty?
    end

    def self.decompress(server, filename)
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
