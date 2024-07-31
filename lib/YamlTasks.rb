# encoding: UTF-8

# SimpleMessageBus implementation for next task, block task etc
# Eventually should be replaced by something smarter by having multilple nested
# lists for different topics
# Want to be done for now
class YamlTasks

  def initialize()
    $YAML_TASKS = self
    $SMB.add(self)
  end

  # [:new_task, "insert|append", view,  "extra_string"]
  def message(message)
    with_tasks do |tasks|
      case message[0]
      when :task_block_for
        space = message[1]
        seconds = message[2]
        puts.call "blocking for #{seconds / 60.0 / 60} hours"
        tasks.block_for(space, seconds)

      when :task_block_by
        tasks.block_by($TIME_LOGGING.current_space, $1)
        space = message[1]
        by = message[2]
        tasks.block_by(space, by)
        $SMB.message([:next_task])

      when :next_task
        # goto next view
        n = tasks.next($TIME_LOGGING.current_space)
        $SMB.message([:action_goto_space, n]) if n

      when :current_task_done
          r = tasks.subtask_done($TIME_LOGGING.current_space, nil)
          puts.call r[:message]
          tasks.save
          space = r[:next]
          $SMB.message([:action_goto_space, space]) if space

      when :new_task
        insert_append = message[1]
        space = message[2]
        rest = message[3]
        h = tasks.hash_by_name(view, space)
        # (?: blocked-by (.*))?
        rest.strip.split(/(?=block-by|block)/).each do |s|
          case s
          when /block(?:-ed)?-by (.*)/
            $1.split(/[, ]/).each {|v| tasks.block_by(view, v) }
          when /block(?:-for)? (.*)/;
            seconds = duration_to_seconds($1)
            tasks.block_for(view, seconds)
          else puts "unkknown option #{s}"
          end
        end
        tasks.save
      end
    end
  end
end
