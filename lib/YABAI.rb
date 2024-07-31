# encoding: UTF-8

class YABAI

  def initialize()
    yabai_thread
  end

  def message(message)
    case message[0]
    when :action_goto_space
      `yabai --space --focus #{message[1]}`
    end
  end



  def yabai_thread()
    @thread_events = Thread.new do
      forever do
        Open3.popen3("yabai --verbose 2>&1") do |stdin, stdout, stderr, wait_thrs|
          begin
            while true do
              line = stdout.readline.strip
              # puts "got line #{line}"
              case line
              when /EVENT_HANDLER_DAEMON_MESSAGE: space --focus (.*)/
                $SMB.message([:space_left, $YABAI_CURRENT_SPACE]) if $YABAI_CURRENT_SPACE
                $SMB.message([:space_entered, $1])
                $YABAI_CURRENT_SPACE = $1
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

# EVENT_HANDLER_MOUSE_DOWN: 800.01, 141.98
# EVENT_HANDLER_MOUSE_DRAGGED: 800.01, 142.49
# EVENT_HANDLER_MOUSE_DRAGGED: 800.01, 143.10
# EVENT_HANDLER_MOUSE_DRAGGED: 800.01, 143.45
# EVENT_HANDLER_MOUSE_DRAGGED: 800.01, 145.75
# EVENT_HANDLER_WINDOW_MOVED: kitty 15703
# EVENT_HANDLER_MOUSE_DRAGGED: 801.24, 153.15
# EVENT_HANDLER_MOUSE_DRAGGED: 804.82, 169.12
# EVENT_HANDLER_MOUSE_DRAGGED: 809.96, 189.84
# EVENT_HANDLER_MOUSE_DRAGGED: 815.86, 211.95
# EVENT_HANDLER_MOUSE_DRAGGED: 822.41, 236.21
# EVENT_HANDLER_MOUSE_DRAGGED: 829.74, 261.02
# EVENT_HANDLER_WINDOW_MOVED: kitty 15703
# EVENT_HANDLER_MOUSE_DRAGGED: 836.85, 283.52
# EVENT_HANDLER_MOUSE_DRAGGED: 842.60, 299.88
# EVENT_HANDLER_MOUSE_DRAGGED: 848.07, 311.79
# EVENT_HANDLER_MOUSE_DRAGGED: 853.38, 321.74
# EVENT_HANDLER_MOUSE_DRAGGED: 857.22, 328.77
# EVENT_HANDLER_MOUSE_DRAGGED: 859.45, 332.33
# EVENT_HANDLER_MOUSE_DRAGGED: 860.55, 333.82
# EVENT_HANDLER_WINDOW_MOVED: kitty 15703
# EVENT_HANDLER_MOUSE_DRAGGED: 861.02, 334.56
# EVENT_HANDLER_WINDOW_MOVED: kitty 15703
# EVENT_HANDLER_MOUSE_UP: 861.02, 334.56
# EVENT_HANDLER_DAEMON_MESSAGE: space --focus 1
# EVENT_HANDLER_APPLICATION_FRONT_SWITCHED: Finder (68148)
# EVENT_HANDLER_SPACE_CHANGED: 1
# space_manager_refresh_application_windows: kitty has windows that are not yet resolved

# EVENT_HANDLER_SPACE_CHANGED: 3
# space_manager_refresh_application_windows: kitty has windows that are not yet resolved
# EVENT_HANDLER_DAEMON_MESSAGE: space --focus 6
# EVENT_HANDLER_SPACE_CHANGED: 7
# space_manager_refresh_application_windows: kitty has windows that are not yet resolved
