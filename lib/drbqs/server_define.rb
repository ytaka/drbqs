module DRbQS

  @@server_create = nil

  def self.define_server(&block)
    if @@server_create
      raise ArgumentError, "The server has already defined."
    end
    @@server_create = block
  end

  def self.start_server(options)
    unless @@server_create
      raise "Can not get server definition."
    end
    server = DRbQS::Server.new(options)
    @@server_create.call(server)
    server.start
    server.wait
  end
end
