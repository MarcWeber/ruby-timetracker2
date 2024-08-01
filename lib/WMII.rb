# encoding: UTF-8


class WMIIR

  def initialize(wmiir)
    @wmiir = wmiir
  end

  def read(arg)
    `#{@wmiir} read #{arg}`
  end

  def write(arg, stdin)
    Open3.popen3("#{@wmiir} write #{arg}") do | input, output, error, wait_thr |
      input.puts stdin
    end
  end

  def current_view
    read("/ctl/").split("\n").find {|line| /^view/ =~ line}.split(" ")[1]
  end

  def set_view(view)
    write("/ctl/", "view #{view}")
    `wmiir xwrite /rbar/little_red_text_bar 'label #{(view.nil? ? "" : view) + " " * 80}'`
  end

  def set_tags(*tags)
    write("/client/sel/tags", tags.join("+"))
  end

end

class WMII

  def initialize()
    $WMIIR = WMIIR.new("wmiir")
    $WMII = self
    start_thread
    $SMB.add(self)
  end

  def message(message)
    case message[0]
    when :action_goto_ttspace
      $WMIIR.set_view(message[1])
    end
  end

  def start_thread()
    @thread_events = Thread.new do
      forever do
        Open3.popen3("wmiir read /event 2>&1") do |stdin, stdout, stderr, wait_thrs|
          begin
            while true do
              line = stdout.readline.strip
              # puts "got line #{line}"
              case line
              when /FocusTag (.*)/
                $SMB.message([:ttspace_left, $WMII_CURRENT_VIEW]) if $WMII_CURRENT_VIEW
                $SMB.message([:ttspace_entered, $1])
                $WMII_CURRENT_VIEW = $1
              when /UnfocusTag (.*)/
                # FocusTag should take care
              end
            end
          rescue Exception => e
            handle_exception(e)
          end
        end
      end
    end
    @thread_events.abort_on_exception = true
    $THREADS << @thread_events
  end
end

