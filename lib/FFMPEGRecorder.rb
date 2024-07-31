# encoding: UTF-8
class FFMPEGRecorder

  begin
  tags_to_record = %w{beefree tasktool}

  case line
  when /FocusTag (.*)/
    if tags_to_record.include?($1)
      file = "/pr/recordings/#{$1}-#{DateTime.now.to_s}.mkv"
      cmd = " "
      puts cmd
      # pid = Process.spawn(cmd)
      pid = Process.spawn(*"/run/current-system/sw/bin/ffmpeg -video_size 1920x1080 -framerate 2 -s 1920x1080 -f x11grab -i :0.0 -vcodec libx264 -crf 0 -preset ultrafast -threads 0 -y #{file}".split(" "))
      FFMPEG_PIDS[$1] = pid
      puts "pid is #{pid}"
    end
  when /UnfocusTag (.*)/
    if tags_to_record.include?($1)
      pid = FFMPEG_PIDS[$1]
      if pid
        puts "killing #{pid}"
        Process.kill("TERM", pid)
        Process.detach(pid)
        FFMPEG_PIDS.delete($1)
      end
    end
  end

  rescue Exception => e
    handle_exception(e)
  end

end
