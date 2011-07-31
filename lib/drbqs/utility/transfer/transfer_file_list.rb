module DRbQS
  # Class for path of files to send from server to a node.
  class Transfer
    class FileList
      # Initialization is executed on server.
      # If :readonly option is true, nodes on same computer as server
      # does not copy files.
      # Therefore, if we edit the files then the change remains.
      # If :readonly option is not true then the files is copied,
      # so the original files are not changed.
      def initialize(*files)
        opts = (Hash === files[-1] ? files.pop : {})
        @readonly = opts[:readonly]
        @files = files.map do |path|
          epath = File.expand_path(path)
          unless File.exist?(epath)
            raise ArgumentError, "#{epath} does not exist."
          end
          epath
        end
        @downloaded = nil
        @path = nil
      end

      # This method is executed on a node.
      def download
        @downloaded = true
        @path = DRbQS::Transfer::Client.get.download(@files, @readonly)
      end

      # Return an array of paths of downloaded files.
      # Note that this method is executed on a node.
      def path
        download unless @downloaded
        @path
      end
    end
  end
end
