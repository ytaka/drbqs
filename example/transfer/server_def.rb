# 
# Usage:
#  drbqs-server server_def.rb
# 

require_relative 'file.rb'

DRbQS.define_server(:finish_exit => true) do |server, argv, opts|
  server_directory = '/tmp/drbqs_transfer_test/'
  FileUtils.rm_r(server_directory) if File.exist?(server_directory)
  server_directory2 = '/tmp/drbqs_transfer_test2/'
  FileUtils.rm_r(server_directory2) if File.exist?(server_directory2)
  FileUtils.mkdir_p(server_directory2)
  test_file = File.join(server_directory2, 'file1.txt')
  open(test_file, 'w') do |f|
    f.puts 'ABC'
  end
  test_dir = File.join(server_directory2, 'test_dir')
  test_dir2 = File.join(test_dir, 'abc', 'def')
  FileUtils.mkdir_p(test_dir2)
  open(File.join(test_dir2, 'file2.txt'), 'w') do |f|
    f.puts 'hello'
  end
  open(File.join(test_dir2, 'file3.txt'), 'w') do |f|
    f.puts 'world'
  end

  tgen = DRbQS::TaskGenerator.new(:sleep_time => 2, :dir => server_directory)
  tgen.set do
    create_add_task(CreateFile.new(1), :create) do |srv, result|
      path = File.join(@dir, result)
      puts "#{path} exist? #{File.exist?(path).inspect}"
    end
    create_add_task(CreateFile.new(2), :create_compress) do |srv, result|
      path = File.join(@dir, result + '.gz')
      puts "#{path} exist? #{File.exist?(path).inspect}"
    end
    create_add_task(CreateDirectory.new(3), :create) do |srv, result|
      path = File.join(@dir, result)
      puts "#{path} exist? #{File.exist?(path).inspect}"
    end
    create_add_task(CreateDirectory.new(4), :create_compress) do |srv, result|
      path = File.join(@dir, result + '.tar.gz')
      puts "#{path} exist? #{File.exist?(path).inspect}"
    end
    create_add_task(ReceiveFile.new(DRbQS::Transfer::FileList.new(test_file)), :read_file) do |srv, result|
      puts result
    end
    create_add_task(ReceiveFile.new(DRbQS::Transfer::FileList.new(test_dir)), :read_directory) do |srv, result|
      puts result
    end
  end
  server.add_task_generator(tgen)

  server.set_file_transfer(server_directory)
end
