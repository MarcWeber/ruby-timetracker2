# encoding: UTF-8
#
# TODO: How about multiple displays ?
# create space for each ttspace and change them at the both time ?
# How can you do time trackig if you choose two different ones ?
require 'concurrent'
require 'json'

def exec2(cmd)
  r = exec(cmd)
  sleep(0.8)
  r
end

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
    @expect_new_space_for = []
    # maps the ttspace name to display names
    # [24, 20] means space 24 on display 0, 20 on display 20
    @active_displays = [1, 2]
    @ttspaces = YamlHashStorage.new("/tmp/timetracker2-ttspace-name-ids", lambda {|| {:focus => nil, :displays => []}})
    $SMB.add(self)

    # FIXME find active display instead and assign
    @active_display = yabai_json("-m query --displays").find {|v| v["has-focus"] }["id"]
    puts "active_display #{@active_display}"
    @expect_new_space_for_yield
    add_yabai_signals
    yabai_threads
  end

  def yabai_json(*args)
    s = `yabai #{args.join(' ')}`
    JSON.parse(s)
  end

  def message(message)
    case message[0]
    when :YABAI_set_active_displays
      @active_displays = message.drop(1).map {|v| Integer(v)}
    when :ttspace_switcher
      puts "starting ttspace switcher"
      Open3.popen3("#{$YABAI_CHOOSER_PATH} 'SELECT A TTSPACE' #{@ttspaces.keys.join(" ")}") do |stdin, stdout, stderr, wait_thrs|
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

      puts ":action_goto_ttspace starting future, known space_nr #{@ttspaces.data.inspect}"

      Concurrent::Promises::future([message, @ttspaces]) {|message, ttspaces|
        begin
          puts ":action_goto_ttspace in future"
          ttspace = message[1]
          puts "3"
          focus_display = ttspaces[ttspace][:focus]
          puts "4"

          sorted_displays = [
            # sort @active_displays by putting the to be focused display last
            *@active_displays.filter {|v| v != focus_display },
            *@active_displays.filter {|v| v == focus_display }
          ]
          puts "sorted_displays #{sorted_displays.inspect}"

          futures = sorted_displays.map do |display|
            # to avoid one focus ?
            c = ttspaces[ttspace]
            space_nr = c[:displays][display]
            [ display,
            if space_nr.nil? then
              Concurrent::Promises::delay([display, space_nr, @expect_new_space_for]) { |display, space_nr, expect_new_space_for|
                begin
                  puts ":action_goto_ttspace caring about display #{display} space_nr not known"
                  f = Concurrent::Promises::resolvable_future
                  expect_new_space_for << {:display => display, :ttspace => ttspace, :resolvable => f}
                  exec2("yabai -m display --focus #{display} # R1920300566")
                  exec2("yabai -m space --create")
                  puts ":action_goto_ttspace caring about display #{display} space_nr not known - space commands done"
                  f.then { |n|
                    puts "got number #{n} for display #{display}"
                    # exec2("yabai -m display --focus #{display} # R1312710259")
                    exec2("yabai -m space --focus #{n} # R1312710258")
                    c[:displays][display] = n
                    ttspaces.save
                  }
                rescue Exception => e
                  handle_exception(e)
                end
              }
            else
              Concurrent::Promises::delay([display, space_nr]) { |display, space_nr|
                begin
                  puts ":action_goto_ttspace caring about display #{display} space_nr known"
                  puts ":action_goto_ttspace caring about display #{display} space_nr known in future"
                  exec2("yabai -m display --focus #{display} # R169850120")
                  exec2("yabai -m space --focus #{space_nr} # R1494551036")
                  space_nr
                rescue Exception => e
                  handle_exception(e)
                end
              }
            end
            ]
          end
          futures.each do |v|
            puts "joined, value #{v[0]}"
            puts v[1].flat.value.inspect
          end
          # space_nrs = Concurrent::Promises::zip(*futures)
          # `yabai -m display --focus #{focus_display}` if focus_display
          # TODO if there are windows on non active displays ?
        rescue Exception => e
          handle_exception(e)
        end
      }
    when :yabai_signal
      case message[1]
      when "display_changed"
        @active_display = Integer(message[2])
      when "space_created"
        # TODO: order could be wrong here? get the one matching the display 
        expect = @expect_new_space_for.pop
        if expect
          puts "got space_nr #{message[3]}"
          expect[:resolvable].fulfill message[3]
          `yabai -m space #{message[3]} --label #{expect[:display]}.#{expect[:ttspace]}`
        end
      when "window_created"
        `yabai -m window --focus #{message[2]}`
      end
    end
  end

  def add_yabai_signals
    yabairc_path = File.join(ENV["HOME"], '.yabairc')
    yabairc = File.read(yabairc_path)
    add_lines = $YABAI_SIGNALS.keys.filter {|k| not yabairc.include? "yabai -m signal --add event=#{k}" }.map {|k|
      # [label=<LABEL>] [app[!]=<REGEX>] [title[!]=<REGEX>] [active=yes|no]
      "yabai -m signal --add event=#{k} action='echo #{k} #{$YABAI_SIGNALS[k][:params]} >> /tmp/yabai-signals' "
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
          last = nil
          begin
            while true do
              line = stdout.readline.strip
              next if line == last
              last = line
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
          last = nil
          begin
            while true do
              line = stdout.readline
              next if line == last
              last = line
              cmd, args = line.strip.split(' ', 2)
              $SMB.message([:yabai_signal, cmd, *args.split(', ')])
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
