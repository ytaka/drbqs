module DRbQS
  class ServerHook
    def initialize
      @hook = Hash.new { |h, k| h[k] = Array.new }
      @argument_number = {}
      @finish_exit = nil
      set_argument_number(:empty_queue, 1)
      set_argument_number(:finish, 1)
    end

    def set_argument_number(key, num)
      @argument_number[key] = num
    end
    private :set_argument_number

    def create_proc_name(key)
      name = "#{key.to_s}#{rand(1000)}"
      if @hook.has_key?(name)
        create_proc_name(key)
      else
        name
      end
    end
    private :create_proc_name

    def add(key, name = nil, &block)
      if (n = @argument_number[key]) && (block.arity != n)
        raise ArgumentError, "Invalid argument number of hook of #{key.inspect}."
      end
      name ||= create_proc_name(key)
      @hook[key] << [name, block]
      name
    end

    def delete(key, name)
      @hook[key].delete_if { |ary| ary[0] == name }
    end

    def specific_proc(key)
      case key
      when :finish
        Kernel.exit if @finish_exit
      end
    end
    private :specific_proc

    def hook_names(key)
      @hook[key].map { |a| a[0] }
    end

    def exec(key, *args)
      @hook[key].each do |ary|
        ary[1].call(*args)
      end
      specific_proc(:finish)
    end
  end

end
