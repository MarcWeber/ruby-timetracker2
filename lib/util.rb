# encoding: UTF-8

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

