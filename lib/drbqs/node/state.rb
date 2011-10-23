module DRbQS
  class Node
    class State
      # Value of state is :sleep, :wait, or :calculate.
      attr_reader :calculating_task

      ALL_STATES = [:sleep, :wait, :calculate, :exit]
      DEFAULT_SLEEP_TIME = 300
      LOADAVG_PATH = '/proc/loadavg'

      def initialize(state_init, process_number, opts = {})
        @process_number = process_number
        @process_state = {}
        @process_number.times do |i|
          @process_state[i] = state_init
        end
        @calculating_task = {}
        @state_after_task = nil


        @load_average_threshold = opts[:max_loadavg]
        @sleep_time = opts[:sleep_time] || DEFAULT_SLEEP_TIME
        @auto_wakeup = nil
      end

      def get_state(wid)
        @process_state[wid]
      end

      def each_worker_id(&block)
        if block_given?
          @process_state.each do |key, val|
            yield(key)
          end
        else
          to_enum(:each_worker_id)
        end
      end

      def waiting_worker_id
        ary = []
        @process_state.each do |wid, state|
          if state == :wait
            ary << wid
          end
        end
        ary
      end

      def request_task_number
        waiting = @process_state.select do |wid, state|
          state == :wait
        end
        waiting.size
      end

      def request?
        @state_after_task != :exit && request_task_number > 0
      end

      def all_workers_waiting?
        each_worker_id.all? do |wid|
          st = get_state(wid)
          st == :wait || st == :exit
        end
      end

      def set_calculating_task(wid, task_id)
        @calculating_task[task_id] = wid
        change(wid, :calculate)
      end

      def set_exit_after_task
        @state_after_task = :exit
        each_worker_id do |wid|
          st = get_state(wid)
          if (st == :wait) && (st == :sleep)
            change(wid, :exit)
          end
        end
      end

      def set_finish_of_task(sent_task_id)
        sent_task_id.each do |task_id|
          if wid = @calculating_task.delete(task_id)
            case @state_after_task
            when :exit
              @process_state[wid] = :exit
            when :sleep
              @process_state[wid] = :sleep
            else
              @process_state[wid] = :wait
            end
          end
        end
      end

      def change(proc_id, state)
        unless ALL_STATES.include?(state)
          raise ArgumentError, "Invalid state of node '#{state}'."
        end
        @process_state[proc_id] = state
      end

      def wakeup_sleeping_worker
        each_worker_id do |wid|
          if get_state(wid) == :sleep
            change(wid, :wait)
          end
        end
        @state_after_task = nil
      end

      def change_to_sleep
        each_worker_id do |wid|
          st = get_state(wid)
          if st == :calculate
            @state_after_task = :sleep
          elsif st != :exit
            change(wid, :sleep)
          end
        end
      end

      def sleep_with_auto_wakeup
        each_worker_id do |wid|
          if get_state(wid) == :wait
            change(wid, :sleep)
          end
        end
        @auto_wakeup = Time.now + @sleep_time
      end

      def wakeup_automatically_for_unbusy_system
        if @auto_wakeup && Time.now > @auto_wakeup && !system_busy?
          each_worker_id do |wid|
            if get_state(wid) == :sleep
              change(wid, :wait)
            end
          end
          @auto_wakeup = nil
          return true
        end
        nil
      end

      def get_load_average
        File.read(LOADAVG_PATH).split[0..2].map do |s|
          s.to_f
        end
      end
      private :get_load_average

      def system_busy?
        if @load_average_threshold && File.exist?(LOADAVG_PATH)
          avg = get_load_average
          if (avg[0] + avg[1]) / 2 >= @load_average_threshold
            return true
          end
        end
        nil
      end
      private :system_busy?

      def change_to_sleep_for_busy_system
        if system_busy?
          sleep_with_auto_wakeup
          return true
        end
        nil
      end

      def ready_to_exit_after_task?
        @state_after_task == :exit && all_workers_waiting?
      end
    end
  end
end
