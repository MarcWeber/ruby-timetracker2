timetracker2
============
Rewrite of my timetracker code for WMII so that it also works with YABAI.
This project serves two use cases
    - track time
    - manage tasks (switch to next task if you get stuck)
      Eg you can block a task for 12h or 2days and it will not show up again


GETTING STARTED
================
Read headlines in this Readme
- SHELL SETUP
- TASKS DEFINITION
- Linux WMII setup or OSX YABAI setup
look at config-example.rb and adjust to your liking

ROADMAP/WARNING
===========================
Refactoring is not complete, so there will be some dead code laying around still

[ ] YABAI related
    [ ] YABAI -> support multiple displays properly
    [ ] YABAI -> replace signals with stdout stream
    [ ] YABAI fix what gets into my way such as 
        [ ] selecting windows on other display by --focus east/west which currently
            doesn't work
    [ ] ubersicht -> show current ttspace title
        Thus make this ruby script have a Network socket

    [ ] YABAI Understand how to use timetracking and multiple displays ?
        [ ] always switch all displays (simple)
        [ ] always switch current display *AND* track this keeping the other untouched

[ ] WMII document version which works
    is MODKEY-t builtin ? its commented in my config to switch views

[ ] document blocked implementations etc

    def reloadable_blocked_custom(o)
        # return true to block
      puts o[:name]

      hash = o[:hash]
      now = o[:now]
      weekday = o[:now].strftime('%u').to_i
      weekend = weekday > 5
      morning = now.hour < 10 and now.hour > 6
      daytime = now.hour < 18
      return true if hash[:name] =~ /morning/ and not morning
      return true if hash[:name] =~ /^low_prio$/ and now.hour < 17
      return true if hash[:'low-prio'] and now.hour < 17
      false
    end

[ ] eventually change task list to nested list or connect to online services

[ ] Just logging everything to /tmp/ might not be smartest idea. Might still
    take a while till it starts mattering. Restarting timetracker2 is easy

[ ] Fix resource consumption / language choice?
    Yes Ruby takes more memory than neccessary, but for protoyping and
    stabilize seems to be a good choice
    Could be rewritten in Crystal easily
    Rust felt like bloat and slowing me down
    JS/TS eventually might have been a nice choice, too
    If I had written from scratch I eventually would have chosen TS

TASKS DEFINITION
================
The tasks file is human editable YAML file.
So you can easily use editor or scripts to change order.
Most important tasks should be put first cause they will be focused to first

DATA_TIMETRACKER = "/x"

/x/work_views (YAML FILE
---
- :name: task1
  limit-day-min: 10
- :name: task2
  blocked-till: '2024-07-31T12:32:01+02:00'

Some features such as limit-day-min are broken at the moment
In the end it's ruby code fix as you like

SHELL SETUP
===========
    ~/.zshrc
    # timetracker2
    tt(){ echo "$@" | socat UNIX-CONNECT:/tmp/timetracker-socket STDIO; }
    tti(){ tt insert "$@"; }
    tta(){ tt append "$@"; }
    ttb(){ tt "block-for $@"; exit; }
    ttbb() { tt block-by "$@"; }

    # st done
    st(){
      tt "st_$1${2:+ }$2";
      [ "$1" = 'done' ] && exit 0
    }
    ttd(){ st_done; }
    # wait for shell command finish
    # currently broken
    ttc(){
      local tmp
      local code
      # tmp="$(tempfile)"
      tmp=/tmp/$RANDOM$RANDOM$RANDOM$RANDOM
      touch "$tmp"
      tt block-while-file-exists "$tmp"
      "$@"; code=$?
      echo CODE $code
      rm $tmp
      return $code
    }


OSX YABAI setup
===============
https://github.com/MarcWeber/swift-yabai-chooser

./config.rb
    $YABAI_CHOOSER_PATH=".."

~/.skhdrc
    # next task
    cmd + shift - n : /bin/sh -c 'echo "next" | socat - UNIX-CONNECT:/tmp/timetracker-socket'
    cmd - b : /bin/sh -c 'echo "previous" | socat - UNIX-CONNECT:/tmp/timetracker-socket'
    cmd + shift - b : /bin/sh -c 'echo "previous 2" | socat - UNIX-CONNECT:/tmp/timetracker-socket'
    cmd - p : /bin/sh -c 'echo "ttspace_switcher" | socat - UNIX-CONNECT:/tmp/timetracker-socket'
    cmd + shift - p : /bin/sh -c 'echo "goto_ttspace pause" | socat - UNIX-CONNECT:/tmp/timetracker-socket'

~/.yabairc
    As soon as the script is started lines like this will get added
    Not all are used yet so may it can be cleaned up
    yabai -m -signal --add event=application_launched action='echo application_launched $YABAI_PROCESS_ID >> /tmp/yabai-signals' 


Linux WMII setup
================
you need wmiimenu

~/.wmii-hg/wmiirc_local

wi_events <<'!'

# open terminal or such
Key $MODKEY-Return #
    LANG=en_US.UTF-8 urxvt -pe tabbed,"searchable-scrollback<M-u>" -sl 20000 -e zsh -l &

# open chromium
Key $MODKEY-c
        if [ $DISPLAY = :0 ]; then chromium --disk-cache-dir=/tmp/browser-cache-chrome --disk-cache-size=20000000; else  chromium --user-data-dir=/tmp/chromium-$DISPLAY; fi &
# open firefox
Key $MODKEY-f 
	firefox &

# timetracker related stuff
# See COmmandLineSocket.rb
# goto next task
Key $MODKEY-shift-n # send next to tt timetracker
	/bin/sh -c 'echo "next" | socat - UNIX-CONNECT:/tmp/timetracker-socket' &


# previous ttspace
Key $MODKEY-b # send next to tt timetracker
	/bin/sh -c 'echo "previous" | socat - UNIX-CONNECT:/tmp/timetracker-socket' &

# ttspace before previos
Key $MODKEY-shift-b # send next to tt timetracker
	/bin/sh -c 'echo "previous 2" | socat - UNIX-CONNECT:/tmp/timetracker-socket' &

# toggle full screen
Key $MODKEY-g # send next to tt timetracker
	wmiir xwrite /client/sel/ctl Fullscreen toggle &

# goto specific ttspace
Key $MODKEY-w #
        # On WMII This also works, but using the socket for consistency
        # xwrite /ctl view web &
        /bin/sh -c 'echo "goto_ttspace web" | socat - UNIX-CONNECT:/tmp/timetracker-socket' &

# goto specific ttspace
Key $MODKEY-SHIFT-p #
        /bin/sh -c 'echo "goto_ttspace pause" | socat - UNIX-CONNECT:/tmp/timetracker-socket' &

# show window on all
Key $MODKEY-SHIFT-a #
        xwrite /client/sel/tags $( wmiir ls /tag | perl -ne 's/\/\n/+/; print') &

!

DEBUGGING
=========
(N)VIM: A mapping like this should do, see def handle_exception(e) in config
nnoremap <f1> :cfile last_error<cr>

