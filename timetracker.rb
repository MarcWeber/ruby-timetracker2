# encoding: UTF-8
require 'date'
require 'fileutils'
require 'open3'
require 'thread'
require 'open3'
require 'socket'
require 'set'
require_relative 'lib/util.rb'
# require_relative 'lib/tasks.rb'
# require_relative 'lib/templates.rb'
puts "TODO templates.rb"
require 'chronic_duration'

begin

  $mutex = Mutex.new

  # -- tasks
  require_relative 'config.rb'
  $LOCK_FILE       ||= "/tmp/lockfile"
  $SOCKET_FILE     ||= "/tmp/timetracker-socket"

  STDOUT.write 'waiting for lock..'
  f = File.open($LOCK_FILE, 'w')
  f.flock(File::LOCK_EX)
  f.puts $PID
  puts "done"

  $THREADS = []
  setup
  $THREADS.each {|v| v.join }

rescue SystemExit, Interrupt
  raise
rescue Exception => e
  handle_exception(e)
else
  # other exception
ensure
  # always executed
end

