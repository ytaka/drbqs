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
