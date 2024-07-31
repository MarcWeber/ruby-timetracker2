# encoding: UTF-8

# allows going to previos space
class Previous

  def initialize()
    $SMB.add(self)
    @previous_spaces = []
  end

  def message(message)
    case message[0]
    when :space_entered
      space = message[1]
      puts "entered #{space}"
      @previous_spaces = [space].concat(@previous_spaces.filter{|v| v != space}.take(5))
    when :action_goto_previous_space
      prev = @previous_spaces[message.fetch(1, 1)]
      puts "goto space #{prev}"
      $SMB.message([:action_goto_space, prev]) if prev
    end
  end

end
