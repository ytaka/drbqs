module DRbQS
  module Test
    class Server < DRbQS::Server
      PROF_FILE = 'drbqs_prof.txt'

      def exit
        throw(:exit_loop)
      end

      def loop_for_test(limit, profile, printer, &block)
        result = { :start => Time.now }
        num = 0
        if profile
          require 'drbqs/server/test/prof'
          result[:profile] = FileName.create(PROF_FILE, :position => :middle)
          prof = DRbQS::Test::Prof.new(printer || :flat, result[:profile])
          prof.start
        end
        begin
          catch(:exit_loop) do
            loop do
              yield
              if limit
                num += 1
                if num >= limit
                  exec_finish_hook
                  break
                end
              end
            end
          end
        rescue Exception => err
          $stdout.puts "*** Error occurs in calculation roop ***"
          b = err.backtrace
          $stdout.puts "#{b[0]}: #{err.to_s} (#{err.class})"
          $stdout.puts b[1..-1].join("\n") if b.size > 1
        end
        if profile
          prof.finish
        end
        result[:end] = Time.now
        result
      end
      private :loop_for_test

      def test_exec(opts = {})
        require 'drbqs/server/test/node'
        first_task_generator_init
        set_file_transfer(nil)
        test_node = DRbQS::Test::Node.new(@logger.level, @ts[:transfer], @ts[:queue])
        n = 0
        data = loop_for_test(opts[:limit], opts[:profile], opts[:printer]) do
          exec_hook
          if ary = test_node.calc
            @queue.exec_task_hook(self, *ary)
            n += 1
          end
        end
        test_node.finalize(@finalization_task)
        data[:task] = n
        data
      end

      def test_task_generator(opts = {})
        @task_generator.each_with_index do |t, i|
          puts "Test task generator [#{i}]"
          t.init
          set_num, task_num = t.debug_all_tasks(opts)
          puts "Create: task sets #{set_num}, all tasks #{task_num}"
        end
      end
    end
  end
end
