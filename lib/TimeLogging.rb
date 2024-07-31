# encoding: UTF-8
class TimeLogging

  attr_reader :current_space

  def initialize()
    $SMB.add(self)
    $TIME_LOGGING = self
    @current_space = nil
  end

  def message(message)
    case message[0]
    when :space_entered
      @current_space = message[1]

      now = Time.new
      @last[:end] = now if @last
      new_ = {:space => @current_space, :start => now }
      if @last
        puts "%s %.2f" % [@last[:space], (@last[:end] - @last[:start]).to_f]
        $SMB.message([:log_time_of_space, @last])
      end
      @last = new_
    end
  end

end
