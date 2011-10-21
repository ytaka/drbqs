require 'drbqs/worker/worker_process_set'

module DRbQS
  # We can use DRbQS::Worker to send some child processes.
  # Note that DRbQS::Worker is not used in DRbQS::Node class and then
  # is not included in main part of DRbQS.
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

    def calculating?
      !@task_pool.empty?
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

    def send_task(proc_key, task_id, task)
      dumped = [task_id] + task.simple_drb_args
      @process.send_task(proc_key, dumped)
    end
    private :send_task

    def add_task(task, broadcast = nil)
      if broadcast
        @process.all_processes.each do |proc_key|
          send_task(proc_key, nil, task)
        end
      else
        task_id = (@task_num += 1)
        @task_pool[task_id] = { :task => task }
        @task_group[task.group] << task_id
        task_id
      end
    end

    # This method sends a stored task for each process that is not calculating a task
    # and responds signals from child processes.
    def step
      @process.waiting_processes.each do |proc_key|
        if @state[proc_key][:sleep]
          next
        end
        catch(:add) do
          grps = (@state[proc_key][:group] || []) + [DRbQS::Task::DEFAULT_GROUP]
          grps.each do |gr|
            @task_group[gr].each do |task_id|
              task_data = @task_pool[task_id]
              if !task_data[:calculate]
                send_task(proc_key, task_id, task_data[:task])
                @task_pool[task_id][:calculate] = true
                throw :add
              end
            end
          end
        end
      end
      @process.respond_signal
    end

    # Wait finish of task +task_id+ with sleep +interval_time+.
    # @param [Fixnum] task_id
    # @param [Numeric] interval_time An argument of Kernel#sleep.
    def wait(task_id, interval_time)
      while @task_pool[task_id]
        unless step
          Kernel.sleep(interval_time)
        end
      end
    end

    # Wait finishes of all tasks with sleep +interval_time+.
    # @param [Numeric] interval_time An argument of Kernel#sleep.
    def waitall(interval_time)
      while calculating?
        unless step
          Kernel.sleep(interval_time)
        end
      end
    end

    # Send signal to exit to all child processes and wait the completion
    # with sleep +interval_time+.
    # @param [Numeric] interval_time An argument of Kernel#sleep.
    def finish(interval_time = 1)
      @process.prepare_to_exit
      @process.waitall(interval_time)
    end
  end
end
