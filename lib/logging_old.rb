# encoding: UTF-8

class Logger_old

  def initialize()
    $SMB.add(self)
  end

  def message(message)
  end


  def show_state_key_value(a, b, ext)
    # puts "#{a}: #{"%.2f" %(b.to_f * 24 * 60)} min"
    lines = []
    lines << "#{"%.2f" %(b.to_f * 24 * 60)} min #{a}"
    if ext
      lines << "by day:  #{$state[:time_by_day][a][$day].inspect rescue ""}"
      lines << "by week: #{$state[:time_by_week][a][$week].inspect rescue ""}"
    end
    return lines.join("\n")
  end

end
