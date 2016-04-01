require 'curses'

module OnePass
  # OnePass Curses UI
  class Password
    def initialize(vault_path)
      @vault_path = vault_path
      @state = :none
      @password = ''

      @config = {
        message: 'Please enter your 1Password master password for the following vault:',
        vault_path: vault_path
      }

      @error_message = nil
    end

    def run
      startup
      refresh
      key_pressed Curses.getch while !(%i(cancel ok).include? @state)
      @state == :ok ? @password : nil
    rescue => ex
    ensure
      shutdown
      puts ex.inspect if ex
      puts ex.backtrace if ex
    end

    def key_pressed(key_pressed)
      case key_pressed
      when Curses::KEY_RESIZE         then resize
      when Curses::KEY_DOWN           then key_up
      when Curses::KEY_UP             then key_down
      when Curses::KEY_LEFT           then key_left
      when Curses::KEY_RIGHT          then key_right
      when *Keys::BACKSPACE           then delete_char
      when Keys::ENTER                then commit
      when Keys::CTRL_C, Keys::ESCAPE then cancel
      else add_char key_pressed if key_pressed
      end
      refresh
    end

    def key_up
    end

    def key_down
    end

    def key_left
      @error_message = nil
      resize
    end

    def key_right
      @error_message = "Incorrect password, please try again"
      resize
    end

    def add_char(char)
      @password << char
    end

    def delete_char
      @password.chop!
    end

    def cancel
      @state = :cancel
    end

    def commit
      @state = :ok
    end

    def startup
      ENV['ESCDELAY'] = '25' # set delay for Escape key to match Vim
      Curses.noecho # do not show typed chars
      Curses.nonl # turn off newline translation
      Curses.stdscr.keypad true # enable arrow keys
      Curses.raw # give us all other keys
      Curses.stdscr.nodelay = 1 # do not block -> we can use timeouts
      Curses.curs_set 0 # hide cursor
      Curses.cbreak
      @screen = Curses.init_screen

      # Curses.start_color
      Curses.timeout = 5
      @window = Curses::Window.new height, width, top, left
    end

    def shutdown
      @window.close if @window
      @screen.close if @screen
      Curses.echo
      Curses.nocbreak
      Curses.nl
      Curses.close_screen
    end

    def width
      width = [@config[:message].length, @config[:vault_path].length].max + 4
      width > Curses.cols ? Curses.cols : width
    end

    def height
      height = @error_message ? 9 : 8
      height > Curses.lines ? Curses.lines : height
    end

    def top
      Curses.lines / 2 - height / 2
    end

    def left
      Curses.cols / 2 - width / 2
    end

    def resize
      @screen.clear
      @window.clear
      @window.resize height, width
      Curses.refresh
    end

    def refresh
      Curses.refresh
      # @window.attron(Colors.pairMap(@color)) if @color
      @window.box 0, 0
      # @window.attroff(Colors.pairMap(@color)) if @color

      print @window, 1, 2, @config[:message], :default
      print @window, 2, 2, @config[:vault_path], :default
      print @window, 3, 2, @error_message, :default if @error_message

      prefix = 'Master Password: '
      password_string = ("*" * @password.length).ljust(width - 4 - prefix.length, '_')
      print @window, height - 4, 2, prefix + password_string, :default

      third = (width - 4) / 3
      print @window, height - 2, 2, '<OK>'.center(third), :default
      print @window, height - 2, (third * 2) + 2, '<Cancel>'.center(third), :default

      @window.refresh
      @screen.refresh
    end

    def print(scr, row, col, text, color, width = (Curses.cols))
      width = [Curses.cols, col + width].min - col
      # t = "%-#{width}s" % [scroll(text, width)]
      # scr.attron(Colors.pairMap(color)) if color
      scr.setpos row, col
      # scr.addstr t
      scr.addstr text
      # scr.attroff(Colors.pairMap(color)) if color
    end

    class Keys
      ENTER = 13
      ESCAPE = 27
      CTRL_C = 3
      BACKSPACE = [263, 127]
    end
  end

  # class OldUI
  #   def initialize(vault_path)
  #     @vault_path = vault_path
  #   end
  #
  #   def password_entry
  #     accumulator = []
  #     Dispel::Screen.open do |screen|
  #       map = Dispel::StyleMap.new(screen.lines)
  #       config = {
  #         map: map,
  #         width: screen.columns,
  #         height: screen.lines,
  #         mode: :password
  #       }
  #       screen.draw *draw_password_box(accumulator.length, config)
  #
  #       Dispel::Keyboard.output do |key|
  #         case key
  #         when :enter
  #           case config[:mode]
  #           when :cancel
  #             raise 'Cancel'
  #           else
  #             break
  #           end
  #         when :backspace
  #           accumulator.pop
  #         when :down
  #           config[:mode] = config[:mode] == :password ? :ok : config[:mode]
  #         when :up
  #           config[:mode] = :password
  #         when :left
  #           config[:mode] = config[:mode] == :password ? config[:mode] : :ok
  #         when :right
  #           config[:mode] = config[:mode] == :password ? config[:mode] : :cancel
  #         else
  #           accumulator.push key if config[:mode] == :password
  #         end
  #         screen.draw *draw_password_box(accumulator.length, config)
  #       end
  #     end
  #     accumulator.join
  #   end
  #
  #   def draw_password_box(pw_length, config)
  #     message = 'Please enter your 1Password master password for the following vault:'
  #     min_width = [message, @vault_path].max_by(&:length).length
  #     prefix = 'Master Password: '
  #
  #     offset_left = (config[:width] - (min_width + 4)) / 2
  #     offset_top = (config[:height] - 8) / 2
  #     left = ' ' * offset_left
  #     third = min_width / 3
  #
  #     password_string = ("*" * pw_length).ljust(min_width - prefix.length, '_')
  #     buttons = '<OK>'.center(third) + ' ' * (min_width - (third * 2)) + '<Cancel>'.center(third)
  #
  #     box  = ("\n" * offset_top)
  #     box += "#{left}┏#{'━' * (min_width + 2)}┓\n"
  #     box += "#{left}┃ #{message.ljust(min_width)} ┃\n"
  #     box += "#{left}┃ #{@vault_path.ljust(min_width)} ┃\n"
  #     box += "#{left}┃ #{' ' * min_width} ┃\n"
  #     box += "#{left}┃ #{prefix}#{password_string} ┃\n"
  #     box += "#{left}┃#{' ' * (min_width + 2)}┃\n"
  #     box += "#{left}┃ #{buttons} ┃\n"
  #     box += "#{left}┗#{'━' * (min_width + 2)}┛\n"
  #
  #     cursor_top = offset_top + (config[:mode] == :password ? 4 : 6)
  #     cursor_left = offset_left
  #     case config[:mode]
  #     when :ok
  #       cursor_left += third / 2
  #     when :cancel
  #       cursor_left += min_width - third + third / 2 - 2
  #     else
  #       cursor_left += prefix.length + pw_length + 2
  #     end
  #
  #     [box, config[:map], [cursor_top, cursor_left]]
  #   end
  # end
end
