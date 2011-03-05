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
