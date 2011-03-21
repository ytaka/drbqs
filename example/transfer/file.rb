require 'fileutils'

class CreateFile
  def initialize(n)
    @n = n
  end

  def output_to_file
    path = "/tmp/transfer_test_#{@n.to_s}.txt"
    open(path, 'w') { |f| f.puts "file#{@n.to_s}" }
    path
  end

  def create
    DRbQS::FileTransfer.enqueue(output_to_file)
    nil
  end

  def create_compress
    DRbQS::FileTransfer.compress_enqueue(output_to_file)
    nil
  end
end

class CreateDirectory
  def initialize(n)
    @n = n
  end

  def output_to_directory
    path = "/tmp/transfer_test_#{@n.to_s}/"
    FileUtils.mkdir_p(path)
    open(File.join(path, 'tmp.txt'), 'w') { |f| f.puts "file#{@n.to_s}" }
    path
  end

  def create
    DRbQS::FileTransfer.enqueue(output_to_directory)
    nil
  end

  def create_compress
    DRbQS::FileTransfer.compress_enqueue(output_to_directory)
    nil
  end
end
