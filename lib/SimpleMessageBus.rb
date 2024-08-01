# encoding: UTF-8

# maybe use something more compilcated later

# [:goto_ttspace, name]
# [:ttspace_entered, name]
# [:action_goto_previous_ttspace [, 1] ]
# [:action_goto_ttspace, [, 1] ]
class SimpleMessageBus

  def initialize()
    @listeners = []
    $SMB = self
  end

  def add(listener)
    @listeners << listener
  end

  def message(message)
    @listeners.each do |v|
      begin
        v.message(message) if v.respond_to? :message
      rescue SystemExit, Interrupt
        raise
      rescue Exception => e
        handle_exception(e)
      end
    end
  end

end
