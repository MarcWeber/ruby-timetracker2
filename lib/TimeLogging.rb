# encoding: UTF-8
class TimeLogging

  attr_reader :current_ttspace

  def initialize()
    $SMB.add(self)
    $TIME_LOGGING = self
    @current_ttspace = nil
  end

  def message(message)
    case message[0]
    when :ttspace_entered
      @current_ttspace = message[1]

      now = Time.new
      @last[:end] = now if @last
      new_ = {:ttspace => @current_ttspace, :start => now }
      if @last
        puts "%s %.2f" % [@last[:ttspace], (@last[:end] - @last[:start]).to_f]
        $SMB.message([:log_time_of_ttspace, @last])
      end
      @last = new_
    end
  end

end
