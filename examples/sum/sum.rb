class Sum
  def initialize(start_num, end_num)
    @num = [start_num, end_num]
  end

  def exec
    sleep(3) # Waiting time to interrupt
    (@num[0]..@num[1]).inject(0) { |sum, i| sum += i }
  end
end
