class Test1
  @@execute_echo_number = 0

  def echo(*args)
    puts "execute Test1#echo(*#{args.inspect.strip})"
    @@execute_echo_number += 1
    args
  end

  def self.get_execute_echo_number
    @@execute_echo_number
  end
end

class Test2

  def echo_wait(wait_time)
    puts "execute Test2#echo(#{wait_time})"
    sleep(wait_time)
    true
  end
end

class Test3
  def temp_file
    dir = DRbQS::Temporary.directory
    file1 = File.join(dir, 'hello')
    open(file1, 'w') do |f|
      f.puts 'hello world'
    end
    file2 = DRbQS::Temporary.file
    open(file2, 'w') do |f|
      f.puts 'temporary'
    end
    puts File.read(file1)
    puts File.read(file2)
    true
  end
end

class TestSum
  def calc(start_num, end_num, step)
    sum = 0
    start_num.step(end_num, step) do |i|
      sum += i
    end
    sum
  end
end
