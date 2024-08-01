# encoding: UTF-8
class CommandLineSocket

  def initialize()
    $SMB.add(self)
    start_thread
  end


  def start_thread()
    File.delete $SOCKET_FILE if File.exist? $SOCKET_FILE
    @thread_tasks = Thread.new do
      forever do
        serv = UNIXServer.new($SOCKET_FILE)
        while s = serv.accept
          begin
            line = s.readline
            $mutex.synchronize do
            handle_command(line, lambda {|line| s.puts line})
            end
          rescue Exception => e
            handle_exception(e)
          ensure
            s.close
          end
        end
      end
    end
    @thread_tasks.abort_on_exception = true
    $THREADS << @thread_tasks
  end

  def handle_command(line, puts)
    case line.strip
    when /^goto_ttspace (.*)$/
      $SMB.message([:action_goto_ttspace, $1])
    when /^previous$/
      $SMB.message([:action_goto_previous_ttspace, 1])
    when /^previous (.*)$/
      $SMB.message([:action_goto_previous_ttspace, Integer($1)])
    when /^ttspace_switcher$/
      $SMB.message([:ttspace_switcher])
    else
    with_tasks do |tasks|
        case line.strip

        when /^(insert|append) ([^ ]*)(.*)$/;
          $SMB.message([:new_task, $1, $2, $3])

        when /^st_done$/
          $SMB.message([:current_task_done])

        when /^next/
          $SMB.message([:next_task])

        when /^block-for (.*)$/;
          seconds = duration_to_seconds($1)
          $SMB.message([:task_block_for, seconds, $WMIIR.current_view,])
          $SMB.message([:next_task])

        when /^block-by (.*)$/;
          $SMB.message([:task_block_by, $WMIIR.current_view, $1])

        when /showc/
          # show current
          key = $WMIIR.current_view
          puts.call $state.inspect
          if $state.fetch(:tasks).include? key
            puts.call show_state_key_value(key, $state.fetch(:tasks).fetch(key), true)
          else
            puts.call "#{key} not found, knows keys #{$state.fetch(:tasks).keys.join(', ')}"
          end

        when /^sample_and_write/
          puts.call tasks.sample_and_write

        when "low-prio"
          h = tasks.hash_by_name($WMIIR.current_view, :insert)
          h[:"low-prio"] = true
          puts "low prio set for #{h[:name]}"
          tasks.save


        when /^memo (.*)/;
          h = tasks.hash_by_name($WMIIR.current_view, :insert)
          h[:memo] = []
          h[:memo] << [Time.now.to_s, $1]
          tasks.save

        when /^append ([^ ]*)(?: blocked-by (.*))?$/;
          h = tasks.hash_by_name($1, :append)
          $2.split(' ').each {|v| tasks.block_by($1, v)} if $2
          tasks.save
        # subtasks

        when /^st_next$/;
          puts.call tasks.subtask_next($WMIIR.current_view)
        when /^st_list$/;
          puts.call tasks.subtask_list($WMIIR.current_view)
        when /^st_next (.*)/;
          puts.call tasks.subtask_next($WMIIR.current_view)
        when /^st_add (.*)/
          end_and_start_current_view(tasks) do
            puts "st_add #{$1}"
            tasks.subtask_add($WMIIR.current_view, $1)
            tasks.save
          end
        when /^st_done$/;
          next_ = end_and_start_current_view(tasks) do
            r = tasks.subtask_done($WMIIR.current_view, nil)
            puts.call r[:message]
            tasks.save
            r[:next]
          end
          $WMIIR.set_view(next_)
        when /^st_done (.*)/;
          end_and_start_current_view(tasks) do
            puts.call tasks.subtask_done($WMIIR.current_view, $1)
            tasks.save
          end

          puts.call tasks.subtask_next($WMIIR.current_view)

        when /^(day|week)-limit-min (.+)$/;
          tasks.limit_min($WMIIR.current_view, $1, Integer($2))

        when /^(append|insert) (.*)$/;
          new_tasks = $2.split(/ */)
          tasks.new_tasks(*new_tasks, $1.to_sym)
          puts.call "#{new_tasks.count} tasks #{$1}ed"


        when /^show$/
          key = $WMIIR.current_view
          puts.call("view #{key}")
          puts.call(show_state_key_value(key, $state.fetch(:tasks).fetch(key), true))

        when /^block-while-file-exists (.*)$/;
          tasks.block_while_file_exists($WMIIR.current_view, $1)
          puts.call tasks.subtask_next($WMIIR.current_view)
          $SMB.message([:next_task])

        # blocking unblocking
        when /^((?:day|week)_min_max)(?: ([0-9]*))?$/;
          current_view = $WMIIR.current_view
          if $2.nil?
            $state[:tasks][current_view].remove($1.to_sym)
          else
            $state[:tasks][current_view][$1.to_sym] = Integer($2)
          end

        when /^block$/;
          # block current view
          current_view = $WMIIR.current_view
          $WORK_VIEWS_BLOCKED << current_view
        when /^block (.*)/;
          # block current view
          $WORK_VIEWS_BLOCKED << $1

        when /^unblock$/;
          # block current view
          $WORK_VIEWS_BLOCKED.delete $1
        when /^unblock (.*)/;
          # unblock current view (to be visited again)
          $WORK_VIEWS_BLOCKED.delete $1

        when /^status$/;
          # toggle maximized view
          puts.call $WORK_VIEWS_BLOCKED.inspect
          puts.call tasks.views.inspect
          puts.call tasks.data.inspect
        when /^goto_max$/;
          case $WMIIR.current_view
          when /max_(.*)/
            $WMIIR.set_view($1)
          when /(.*)/
            $WMIIR.set_view("max_#{$1}")
          end

        when /^toggle_max$/
          # move window to max_
          # or move it back and switch view
          case $WMIIR.current_view
          when /max_(.*)/
            $WMIIR.set_tags($1) # only on mayn
            $WMIIR.set_view($1)
          when /(.*)/
            max = "max_#{$1}"
            $WMIIR.set_tags($1, max) # on max and original view
            $WMIIR.set_view(max)
          end
        else
          $SMB.message(line.strip.split(' '))
        end
      end
    end
  end
end
