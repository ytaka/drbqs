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
    path = output_to_file
    DRbQS::Transfer.enqueue(path)
    File.basename(path)
  end

  def create_compress
    path = output_to_file
    DRbQS::Transfer.compress_enqueue(path)
    File.basename(path)
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
    dir = output_to_directory
    DRbQS::Transfer.enqueue(dir)
    File.basename(dir)
  end

  def create_compress
    dir = output_to_directory
    DRbQS::Transfer.compress_enqueue(dir)
    File.basename(dir)
  end
end

class ReceiveFile
  def initialize(file_list)
    @file_list = file_list
  end

  def read_file
    ret = ''
    @file_list.path.each do |path|
      if File.directory?(path)
        raise "Receive directory, not file."
      end
      ret << path << "\t" << File.read(path).strip << "\n"
    end
    ret
  end

  def read_directory
    ret = ''
    @file_list.path.each do |dir|
      unless File.directory?(dir)
        raise "Receive file, not directory."
      end
      Dir.glob("#{dir}/**/*.txt").each do |path|
        ret << path << "\t" << File.read(path).strip << "\n"
      end
    end
    ret
  end
end
