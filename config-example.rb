require 'date'
# encoding: UTF-8
CONFIG_DIR = "#{ENV['HOME']}/.config/tt"

FileUtils.mkdir_p CONFIG_DIR

IMPLEMENTATION = :YABAI  # :YABAI or :WMII
DATA_TIMETRACKER = File.join(ENV["MR_data"], "data-timetracker")
TASKS_FILE     = File.join(DATA_TIMETRACKER, "work_views")
TEMPLATE_FILES= [File.join(DATA_TIMETRACKER, "work_views_templates")]
TEMPLATE_INSTANTIATED_CACHE_FILE="#{TEMPLATE_FILES[0]}.instantiated" # caches what templates have been instantiated already

$NEW_TASK_MERGE = {
  'limit-day-min'.to_s => 10
}

$STATE_FILE = "#{CONFIG_DIR}/state"
$PID = "#{CONFIG_DIR}/.ruby-timetracker.lock"

def blocked_custom(o)
  load '/pr/projects-checked-out/ruby/timetracker/blocked_custom.rb'
  return reloadable_blocked_custom(o)
  # # return true to block
  # puts o[:name]
  # hash = o[:hash]
  # now = o[:now]
  # weekday = o[:now].strftime('%u').to_i
  # weekend = weekday > 5
  # morning = now.hour < 10 and now.hour > 6
  # daytime = now.hour < 18
  # return true if hash[:name] =~ /morning/ and not morning
  # return true if hash[:name] =~ /^low_prio$/ and now.hour < 17
  # return true if hash[:'low-prio'] and now.hour < 17
  # false
end

FFMPEG_PIDS = {}

def setup()
  require_relative 'lib/tasks'
  require_relative 'lib/SimpleMessageBus.rb'
  require_relative 'lib/TimeLogging.rb'
  require_relative 'lib/SqliteLogger.rb'
  require_relative 'lib/Previous.rb'
  require_relative 'lib/YABAI.rb'
  require_relative 'lib/WMII.rb'
  require_relative 'lib/UserInteractions.rb'
  require_relative 'lib/CommandLineSocket.rb'
  require_relative 'lib/YamlTasks.rb'

  SimpleMessageBus.new
  CommandLineSocket.new
  Previous.new
  case IMPLEMENTATION
  when :YABAI; YABAI.new
  when :WMII; WMII.new
  end
  YamlTasks.new # nach WMIIR
  TimeLogging.new
  # Logger_old.new
  SqliteLogger.new
  UserInteractions.new
end

def handle_exception(e)
    # $SMB.message([:exception, e])
    puts e.message
    puts e.backtrace.join("\n")
    File.open("last_error", 'wb') { |file| 
      file.puts(e.message)
      file.puts(e.backtrace.join("\n"))
    }
end

