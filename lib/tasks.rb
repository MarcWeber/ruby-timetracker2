# encoding: UTF-8

require 'yaml'

class Tasks

  attr_reader :data

  def initialize(path)
    @path  = path
  end

  def load
    begin
      sample_and_write unless File.exist? @path
      @data = File.open(@path, 'rb') { |file| YAML::load(file) }
    rescue
      handle_exception(e)
      raise "problem loading #{@path}\nExample #{[{:name => 'task'}].to_yaml}"
    end
  end

  def sample_and_write
    puts "writing sample to #{@path}"
    @data = [
      {:name => "abc", :subtasks =>[ "st1", "st2"]},
      {:name => "task1"},
      {:name => "task2"},
      {:name => "complete",
       :subtasks => ['sub1','sub2'],
       :'blocked-till' => '2019-11-09T11:29:09+01:00',
       :'limit-day-min' => 20,
       :'blocked-by' => ['task1', 'task2']
    },
    ]
    save
  end

  def save
    # if disk is full don't loose state (eg btrfs), thus save, once saving is complete rename
    File.open("#{@path}.tmp", 'wb') { |file| YAML::dump(@data, file) }
    File.rename("#{@path}.tmp", @path)
  end

  def views
    @data.map {|v| v[:name]}
  end

  def view(n)
    @data[n][:name]
  end

  def index(idx_or_name)
    case idx_or_name
    when String; idx_by_name(idx_or_name)
    when Integer;    idx_or_name
    end
  end

  def hash_by_name(name, op = :append)
    i = index(name)
    h = if i.nil?
          h = {:name => name}.merge($NEW_TASK_MERGE)
          case op
          when :append
            @data << h
          when :insert
            @data.insert(0, h)
          else throw "bad"
          end
          h
        else
          @data[i]
        end
    h[:subtasks] ||= []
    h
  end

  def idx_by_name(name)
    views.find_index(name)
  end

  def limit_min(name, what, min)
    raise "week or day expected" unless ["week", "day"].include? what
    hash_by_name(name)[:"limit-#{what}-min"] = min
    save
  end

  def block_for(name, seconds_from_now)
    hash_by_name(name)["blocked-till".to_s] = (DateTime.now + seconds_from_now / 60.0 / 60 / 24.0).to_s
    save
  end


  def new_tasks(*names, op)
    names.each do |name|
      hash_by_name(name, op)
    end
    save
  end

  def block_while_file_exists(name, other)
    h = hash_by_name(name)
    h[:"block-while-file-exists"] = other
    save
  end

  def block_by(name, other)
    h = hash_by_name(name)
    h[:"blocked-by"] ||= []
    h[:"blocked-by"] << other
    h[:"blocked-by"].uniq!
    h[:"blocked-by-since"] = DateTime.now.to_s

    # create that other task, too
    hash_by_name(other, :insert)
    save
  end

  def blocked_by_date(now, hash)
    date_str = hash["blocked-till".to_s]
    return false if date_str.nil?
    begin
      parsed = DateTime.parse(date_str)
      d = (now - parsed).to_f 
      puts "#{hash[:name]} #{date_str} now: #{now.to_s} diff #{d}, parsed: #{parsed.to_s} #{d <= 0}"
      d <= 0
    rescue Exception => e
      handle_exception(e)
      raise "failed parsing date #{date_str}"
    end
  end

  def blocked_by_name(hash)
    hash.fetch('blocked-by'.to_sym, []).find {|x| idx_by_name(x) }
  end

  def blocked_custom(o)
    # must be defined in config.rb just return false if you don't need it
    Kernel.send(:blocked_custom, o)
  end

  def wrong_time(hash)
    now = DateTime.now
    ac = hash[:"after-clock"]
    if ac
      ac = ac.split(":").map {|v| Float(v) }
      puts ac.inspect
      now = DateTime.now
      ac = DateTime.new(now.year, now.month, now.day, ac[0], ac[1], 0, now.zone)
      return true if now < ac
    end
  end

  def limit_exceeded(hash)
    name = hash[:name]
    spent = {
      :week => ($state[:time_by_week][name][$week] rescue nil),
      :day  => ($state[:time_by_day][name][$day]   rescue nil)
    }

    hash = hash_by_name(name)
    limit = {
      :day =>  hash[:"limit-day-min"],
      :week => hash[:"limit-week-min"]
    }

    [:day, :week].each do |what|
      if not limit[what].nil? and not spent[what].nil?
        puts "spent #{spent[what]} limit #{limit[what]}"
        diff = spent[what] - limit[what] 
        if diff > 0
          return true 
        end
      end
    end

    return false
  end

  def blocked_while_file_exists(hash)
    f = hash[:hash][:"block-while-file-exists"]
    !!(f and File.exist? f)
  end

  def blocked(now, hash)
    o = {:now => now, hash: hash}
    !hash.fetch(:active, true)
    blockings = [
      {:name => "blocked_by_date",:expr => lambda { blocked_by_date(now, hash) } },
      {:name => "blocked_by_name",:expr => lambda { blocked_by_name(hash) } },
      {:name => "limit_exceeded",:expr => lambda { limit_exceeded(hash)  } },
      {:name => "wrong_time",:expr => lambda { wrong_time(hash)  } },
      {:name => "blocked_custom",:expr => lambda { blocked_custom(o)  } },
      {:name => "blocked_while_file_exists",:expr => lambda { blocked_while_file_exists(o) } },
    ]

    blockings.each do |x|
      c = x[:expr].call
      if c
        # puts "#{hash[:name]} blocked by #{x[:name]}"
        return true
      end
    end
    false
  end

  def next_or_nil_this_prio(view, prio)
    view = "" if view.nil?

    now = DateTime.now
    views_total = views.count

    current_view = view
    current_view.gsub!(/^max_/, '')
    current_idx = idx_by_name(current_view)

    stop = nil
    n = if current_idx.nil?
      0
    else
      stop = current_idx
      (current_idx + 1) % views_total
    end

    while stop.nil? || stop != n
      stop = n if stop.nil?
      hash = @data[n % views_total]
      if not blocked(now, hash) and hash.fetch(:prio, 0) >= prio
        return hash[:name]
      end
      n= (n+1) % views_total
    end
    nil
  end

  def next_with_all_prios(view)
    prios = @data.map {|v| v.fetch(:prio, 0)}
    max = prios.max
    min = prios.min

    n = nil
    max.downto(min) do |p|
      n = next_or_nil_this_prio(view, p)
      break unless n.nil? or n == view
    end
    n
  end

  def next(view)
    n = next_with_all_prios(view)
    n = views.first if n.nil?
    n
  end

  def subtask_next(view)
    hash_by_name(view)[:subtasks][-1]
  end

  def subtask_with_label(view)
    h = hash_by_name(view)
    return view if h.nil? or h.fetch(:subtasks, []).count == 0
    "#{view}:#{h[:subtasks][-1]}"
  end

  def subtask_add(view, task)
    hash_by_name(view)[:subtasks] << task
  end

  def subtask_list(view)
    hash_by_name(view)[:subtasks]
  end

  def subtask_done(view, task)
    a = hash_by_name(view)
    task = subtask_next(view) unless task
    if a[:subtasks].count == 0
      # last, task, remove view
      next_ = self.next(view) 
      @data.delete_at index(view)
      {:msg => "view #{view} removed", :next => next_}
    else
      a[:subtasks].select! {|v| v!= task}
      "task #{task} removed"
      a.delete :subtasks if a[:subtasks].count == 0
      {:msg => "view #{view} removed", :next => nil }
    end
  end

end
