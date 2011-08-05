module DRbQS
  class Server
    module ACLFile

      # Create ACL object from file.
      # @example Deny hosts except for localhost
      #  deny all
      #  allow localhost
      #  allow 127.0.0.1
      def self.load(path)
        ACL.new(File.read(path).split)
      end
    end
  end
end
