require 'drbqs/worker/worker_process_set'

module DRbQS
  class Worker
    attr_reader :process

    def initialize(opts = {})
      @process = DRbQS::Worker::ProcessSet.new(opts[:class])
      if opts[:key]
        opts[:key].each do |key|
          @process.create_process(key)
        end
      end
      @state = Hash.new { |h, k| h[k] = Hash.new }
      @task_pool = {}
      @task_group = Hash.new { |h, k| h[k] = Array.new }
      @task_num = 0
    end

    def sleep(*keys)
      keys.each do |key|
        @state[key][:sleep] = true
      end
    end

    def wakeup(*keys)
      keys.each do |key|
        @state[key][:sleep] = false
      end
    end

    def group(grp, *keys)
      keys.each do |key|
        (@state[key][:group] ||= []) << grp
      end
    end

    def on_result(&block)
      @process.on_result do |proc_key, ary|
        task_id, result = ary
        if task_data = @task_pool.delete(task_id)
          task = task_data[:task]
          @task_group[task.group].delete(task_id)
          task.exec_hook(self, result)
        end
        block.call(proc_key, ary)
      end
    end

    def on_error(&block)
      @process.on_error(&block)
    end

    def add_task(task)
      task_id = (@task_num += 1)
      @task_pool[task_id] = { :task => task }
      @task_group[task.group] << task_id
    end

    def step
      if waiting = @process.waiting_process
        waiting.each do |proc_key|
          if @state[proc_key][:sleep]
            next
          end
          catch(:add) do
            grps = (@state[proc_key][:group] || []) + [DRbQS::Task::DEFAULT_GROUP]
            grps.each do |gr|
              @task_group[gr].each do |task_id|
                task_data = @task_pool[task_id]
                if !task_data[:calculate]
                  dumped = [task_id] + task_data[:task].simple_drb_args
                  @process.send_task(proc_key, dumped)
                  @task_pool[task_id][:calculate] = true
                  throw :add
                end
              end
            end
          end
        end
      end
      @process.respond_signal
    end

      # def send_task_to_waiting_process(dumped_task_ary)
      #   key_not_working = nil
      #   @process.each do |key, h|
      #     if h[:task].empty?
      #       key_not_working = key
      #     end
      #   end
      #   if key_not_working
      #     send_task(key_not_working, dumped_task_ary)
      #     key_not_working
      #   else
      #     nil
      #   end
      # end
  end
end
