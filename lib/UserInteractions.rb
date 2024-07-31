# encoding: UTF-8# encoding: UTF-8
class UserInteractions

  def initialize()
    thread_start
  end

  def message()
  end

  def thread_start

    @thread_user_input = Thread.new do
      forever do
        line = STDIN.readline.strip
        # puts "got command #{line.inspect}"
        case line
        when ''
        when /reset\s+(.*)/
          key = $1.strip
          if $state.fetch(:tasks).include? key
            puts show_state_key_value(key, $state.fetch(:tasks).fetch(key), true)
            $state.fetch(:tasks).delete key
          else
            puts "#{key} not found, knows keys #{$state.fetch(:tasks).keys.join(', ')}"
          end
        when /showc/
          # show current
          key = $WMIIR.current_view
          if $state.fetch(:tasks).include? key
            puts show_state_key_value(key, $state.fetch(:tasks).fetch(key), true)
          else
            puts "#{key} not found, knows keys #{$state.fetch(:tasks).keys.join(', ')}"
          end
        when /show\s+(.*)/
          key = $1.strip
          if $state.fetch(:tasks).include? key
            puts show_state_key_value(key, $state.fetch(:tasks).fetch(key), true)
          else
            puts "#{key} not found, knows keys #{$state.fetch(:tasks).keys.join(', ')}"
          end
        when 'show_current'
          $WMIIR.current_view
        when 'show_ext'
          $state.show_state(:ext => true)
        when 'show'
          $SQLITE_LOGGER.print_last_reset(false)
        when 'reset'
          $SQLITE_LOGGER.print_last_reset(true)
        else
          puts "unknown command #{line.inspect}, known: reset, show"
        end
      end
    end
    @thread_user_input.abort_on_exception
    $THREADS << @thread_user_input
  end
end
