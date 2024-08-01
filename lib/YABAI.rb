# encoding: UTF-8
#
# TODO: How about multiple displays ?
# create space for each ttspace and change them at the both time ?
# How can you do time trackig if you choose two different ones ?

$YABAI_SIGNALS = {}
$YABAI_SIGNALS["application_launched"] = {:params =>  "$YABAI_PROCESS_ID", :description => " Triggered when a new application is launched.  Eligible for app filter. Passes one argument: " }
$YABAI_SIGNALS["application_terminated"] = {:params =>  "$YABAI_PROCESS_ID", :description => " Triggered when an application is terminated.  Eligible for app and active filter. Passes one argument: " }
$YABAI_SIGNALS["application_front_switched"] = {:params =>  "$YABAI_PROCESS_ID, $YABAI_RECENT_PROCESS_ID", :description => " Triggered when the front-most application changes.  Passes two arguments: " }
$YABAI_SIGNALS["application_activated"] = {:params =>  "$YABAI_PROCESS_ID", :description => " Triggered when an application is activated.  Eligible for app filter. Passes one argument: " }
$YABAI_SIGNALS["application_deactivated"] = {:params =>  "$YABAI_PROCESS_ID", :description => " Triggered when an application is deactivated.  Eligible for app filter. Passes one argument: " }
$YABAI_SIGNALS["application_visible"] = {:params =>  "$YABAI_PROCESS_ID", :description => " Triggered when an application is unhidden.  Eligible for app filter. Passes one argument: " }
$YABAI_SIGNALS["application_hidden"] = {:params =>  "$YABAI_PROCESS_ID", :description => " Triggered when an application is hidden.  Eligible for app and active filter. Passes one argument: " }
$YABAI_SIGNALS["window_created"] = {:params =>  "$YABAI_WINDOW_ID", :description => " Triggered when a window is created.  Also applies to windows that are implicitly created at application launch. Eligible for app and title filter. Passes one argument: " }
$YABAI_SIGNALS["window_destroyed"] = {:params =>  "$YABAI_WINDOW_ID", :description => " Triggered when a window is destroyed.  Also applies to windows that are implicitly destroyed at application exit. Eligible for app and active filter. Passes one argument: " }
$YABAI_SIGNALS["window_focused"] = {:params =>  "$YABAI_WINDOW_ID", :description => " Triggered when a window becomes the key-window.  Eligible for app and title filter. Passes one argument: " }
$YABAI_SIGNALS["window_moved"] = {:params =>  "$YABAI_WINDOW_ID", :description => " Triggered when a window changes position.  Eligible for app, title and active filter. Passes one argument: " }
$YABAI_SIGNALS["window_resized"] = {:params =>  "$YABAI_WINDOW_ID", :description => " Triggered when a window changes dimensions.  Eligible for app, title and active filter. Passes one argument: " }
$YABAI_SIGNALS["window_minimized"] = {:params =>  "$YABAI_WINDOW_ID", :description => " Triggered when a window has been minimized.  Eligible for app, title and active filter. Passes one argument: " }
$YABAI_SIGNALS["window_deminimized"] = {:params =>  "$YABAI_WINDOW_ID", :description => " Triggered when a window has been deminimized.  Eligible for app and title filter. Passes one argument: " }
$YABAI_SIGNALS["window_title_changed"] = {:params =>  "$YABAI_WINDOW_ID", :description => " Triggered when a window changes its title.  Eligible for app, title and active filter. Passes one argument: " }
$YABAI_SIGNALS["space_created"] = {:params =>  "$YABAI_SPACE_ID, $YABAI_SPACE_INDEX", :description => " Triggered when a space is created.  Passes two arguments: " }
$YABAI_SIGNALS["space_destroyed"] = {:params =>  "$YABAI_SPACE_ID", :description => " Triggered when a space is destroyed.  Passes one argument: " }
$YABAI_SIGNALS["space_changed"] = {:params =>  "$YABAI_SPACE_ID, $YABAI_SPACE_INDEX, $YABAI_RECENT_SPACE_ID, $YABAI_RECENT_SPACE_INDEX", :description => " Triggered when the active space has changed.  Passes four arguments: " }
$YABAI_SIGNALS["display_added"] = {:params =>  "$YABAI_DISPLAY_ID, $YABAI_DISPLAY_INDEX", :description => " Triggered when a new display has been added.  Passes two arguments: " }
$YABAI_SIGNALS["display_removed"] = {:params =>  "$YABAI_DISPLAY_ID", :description => " Triggered when a display has been removed.  Passes one argument: " }
$YABAI_SIGNALS["display_moved"] = {:params =>  "$YABAI_DISPLAY_ID, $YABAI_DISPLAY_INDEX", :description => " Triggered when a change has been made to display arrangement.  Passes two arguments: " }
$YABAI_SIGNALS["display_resized"] = {:params =>  "$YABAI_DISPLAY_ID, $YABAI_DISPLAY_INDEX", :description => " Triggered when a display has changed resolution.  Passes two arguments: " }
$YABAI_SIGNALS["display_changed"] = {:params =>  "$YABAI_DISPLAY_ID, $YABAI_DISPLAY_INDEX, $YABAI_RECENT_DISPLAY_ID, $YABAI_RECENT_DISPLAY_INDEX", :description => " Triggered when the active display has changed.  Passes four arguments: " }
$YABAI_SIGNALS["mission_control_enter"] = {:params =>  "$YABAI_MISSION_CONTROL_MODE", :description => " Triggered when mission-control activates.  Passes one argument: " }
$YABAI_SIGNALS["mission_control_exit"] = {:params =>  "$YABAI_MISSION_CONTROL_MODE", :description => " Triggered when mission-control deactivates.  Passes one argument:" }
$YABAI_SIGNALS["dock_did_change_pref"] = {:description => "# Triggered when the macOS Dock preferences changes." }
$YABAI_SIGNALS["system_woke"] = {:description => "Triggered when macOS wakes from sleep." }

class YABAI

  def initialize()
    yabai_threads
    @spaces = YamlHashStorage.new("/tmp/timetracker2-ttspace-name-ids")
    $SMB.add(self)
    add_yabai_signals
  end

  def message(message)
    puts message.inspect
    case message[0]
    when :ttspace_switcher
      puts "starting ttspace switcher"
      Open3.popen3("#{$YABAI_CHOOSER_PATH} 'SELECT A SPACE' #{@ttspaces.keys.join(" ")}") do |stdin, stdout, stderr, wait_thrs|
        ttspace = stdout.readline.strip
        $SMB.message([:action_goto_ttspace, ttspace])
      end

    when :osx_space_entered
      # when you use mouse or mission control to switch ttspace and we know about it
      # should we change time tracking ?
      # complicated because each display can have it's own ttspace ?
      # better do it manually ?
      # ttspace = @ttspaces.invert[message[1]]
      # $SMB.message([:space_entered, ttspace]) if ttspace

    when :action_goto_ttspace
      ttspace = message[1]
      space_nr = @ttspaces[ttspace]
      if space_nr.nil?
        puts "space_nr unknown"
        @catch_new_space_and_name_it = ttspace
        `yabai -m space --create`
      else
        `yabai -m space --focus #{space_nr}`
      end
    when :yabai_signal
      case message[1]
      when "space_created"
        if @catch_new_ttspace_and_name_it
          ttspace = @catch_new_ttspace_and_name_it
          @catch_new_ttspace_and_name_it = nil
          @ttspaces[ttspace] = message[3]
          $SMB.message([:action_goto_ttspace, ttspace])
          `yabai -m space #{message[3]} --label #{ttspace}`
        end
      when "window_created"
        puts message.inspect
        `yabai -m window --focus #{message[2]}`
      end
    end
  end

  def add_yabai_signals
    yabairc_path = File.join(ENV["HOME"], '.yabairc')
    yabairc = File.read(yabairc_path)
    add_lines = $YABAI_SIGNALS.keys.filter {|k| not yabairc.include? "yabai -m -signal --add event=#{k}" }.map {|k|
      # [label=<LABEL>] [app[!]=<REGEX>] [title[!]=<REGEX>] [active=yes|no]
      "yabai -m -signal --add event=#{k} action='echo #{k} #{$YABAI_SIGNALS[k][:params]} >> /tmp/yabai-signals' "
    }.join("\n")
    if add_lines != ""
      puts "adding lines\n#{add_lines} to #{yabairc_path}"
      File.open(yabairc_path, 'ab') { |file| file.puts([yabairc, add_lines ].join("\n")) } 
    end
  end

  def yabai_threads()

    @thread_events = Thread.new do
      forever do
        Open3.popen3("tail -F /tmp/yabai-log") do |stdin, stdout, stderr, wait_thrs|
          # stdin.puts($SUDO_PASSWORD)
          begin
            while true do
              line = stdout.readline.strip
              # puts "got line #{line}"
              case line
              when /EVENT_HANDLER_DAEMON_MESSAGE: space --focus (.*)/
                $SMB.message([:osx_space_entered, $1])
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


    @thread_yabai_signals = Thread.new do
      forever do
        Open3.popen3("tail -F /tmp/yabai-signals") do |stdin, stdout, stderr, wait_thrs|
          begin
            while true do
              line = stdout.readline.strip
              $SMB.message([:yabai_signal, *line.split(' ')])
            end
          rescue Exception => e
            handle_exception(e)
          end
        end
      end
    end
    @thread_yabai_signals.abort_on_exception = true
    $THREADS << @thread_yabai_signals
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
