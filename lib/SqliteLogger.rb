# encoding: UTF-8
require "sqlite3"
require 'date'

class SqliteLogger

  attr_reader :db

  def initialize()
    $SQLITE_LOGGER = self

    $SMB.add(self)
    @last_ttspace = nil

    @db_path = File.join(ENV["HOME"], '.timetracker.sqlite')
    @db = SQLite3::Database.new(@db_path)

    tables = @db.execute("SELECT name FROM sqlite_master WHERE type='table'")

    if tables.length == 0 then
@db.execute <<-SQL
  CREATE TABLE ttspace_times (
    ttspace varchar(80),
    start DATETIME,
    end DATETIME,
    seconds DOUBLE
  );
SQL

@db.execute <<-SQL
  CREATE TABLE resets (
    reset DATETIME
  );
SQL
      insert_reset
    end
  end

  def message(message)
    case message[0]
    when :log_time_of_ttspace
      x = message[1]
      @db.execute("insert into ttspace_times values ( ?, ?, ?, ? )", [x[:ttspace], x[:start].to_s, x[:end].to_s, ((x[:end] - x[:start])).to_f])
    end
  end

  def print_last_reset(reset)

    db.execute("
    SELECT ttspace, SUM(seconds)
    FROM ttspace_times
    WHERE start > (SELECT max(reset) FROM resets)
    GROUP BY ttspace
    ") do |row|
      puts "%s %.2f" % row
    end

    if reset
      insert_reset
      puts "resetted"
    end

  end

  def insert_reset
      @db.execute "insert into resets values (? )", Time.now.to_s
  end

end
