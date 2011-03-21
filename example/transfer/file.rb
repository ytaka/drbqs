class CreateFile
  def initialize(n)
    @n = n
  end

  def create
    path = "/tmp/transfer_test_#{@n.to_s}.txt"
    open(path, 'w') { |f| f.puts "file#{@n.to_s}" }
    DRbQS::FileTransfer.compress_enqueue(path)
    nil
  end
end
