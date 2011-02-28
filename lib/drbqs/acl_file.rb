module DRbQS
  module ACLFile

    # Create ACL object from file.
    # The example of file is the following:
    # deny all
    # allow localhost
    # allow 127.0.0.1
    def self.load(path)
      ACL.new(File.read(path).split)
    end
  end
end
