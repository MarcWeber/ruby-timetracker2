# encoding: UTF-8

def handle_exception(e)
    # $SMB.message([:exception, e])
    puts e.message
    puts e.backtrace.join("\n")
    File.open("last_error", 'wb') { |file| 
      file.puts(e.message)
      file.puts(e.backtrace.join("\n"))
    }
end

def forever()
  while true
    begin
      yield
    rescue Exception => e
      handle_exception(e)
    end
    sleep(5)
  end
end

def with_tasks
  tasks = Tasks.new(TASKS_FILE)
  tasks.load
  yield tasks
end

