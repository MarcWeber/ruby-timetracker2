# encoding: UTF-8

# allows going to previos ttspace
class Previous

  def initialize()
    $SMB.add(self)
    @previous_ttspaces = []
  end

  def message(message)
    case message[0]
    when :ttspace_entered
      ttspace = message[1]
      puts "entered #{ttspace}"
      @previous_ttspaces = [ttspace].concat(@previous_ttspaces.filter{|v| v != ttspace}.take(5))
    when :action_goto_previous_ttspace
      prev = @previous_ttspaces[message.fetch(1, 1)]
      puts "goto ttspace #{prev}"
      $SMB.message([:action_goto_ttspace, prev]) if prev
    end
  end

end
