require 'dispel'

module OnePass
  # OnePass Application
  class Application
    CONFIG_PATH='~/.one_pass'

    def initialize(vault_path = nil)
      @vault_path = get_vault vault_path
      @vault = OpVault.new @vault_path

      @vault.unlock password_entry
      @vault.load_items
    end

    def password_entry
      accumulator = []
      Dispel::Screen.open do |screen|
        map = Dispel::StyleMap.new(screen.lines)
        config = {
          map: map,
          width: screen.columns,
          height: screen.lines,
          mode: :password
        }
        screen.draw *draw_password_box(accumulator.length, config)

        Dispel::Keyboard.output do |key|
          case key
          when :enter
            case config[:mode]
            when :cancel
              raise 'Cancel'
            else
              break
            end
          when :backspace
            accumulator.pop
          when :down
            config[:mode] = config[:mode] == :password ? :ok : config[:mode]
          when :up
            config[:mode] = :password
          when :left
            config[:mode] = config[:mode] == :password ? config[:mode] : :ok
          when :right
            config[:mode] = config[:mode] == :password ? config[:mode] : :cancel
          else
            accumulator.push key if config[:mode] == :password
          end
          screen.draw *draw_password_box(accumulator.length, config)
        end
      end
      accumulator.join
    end

    def draw_password_box(pw_length, config)
      message = 'Please enter your 1Password master password for the following vault:'
      min_width = [message, @vault_path].max_by(&:length).length
      prefix = 'Master Password: '

      offset_left = (config[:width] - (min_width + 4)) / 2
      offset_top = (config[:height] - 8) / 2
      left = ' ' * offset_left
      third = min_width / 3

      password_string = ("*" * pw_length).ljust(min_width - prefix.length, '_')
      buttons = '<OK>'.center(third) + ' ' * (min_width - (third * 2)) + '<Cancel>'.center(third)

      box  = ("\n" * offset_top)
      box += "#{left}┏#{'━' * (min_width + 2)}┓\n"
      box += "#{left}┃ #{message.ljust(min_width)} ┃\n"
      box += "#{left}┃ #{@vault_path.ljust(min_width)} ┃\n"
      box += "#{left}┃ #{' ' * min_width} ┃\n"
      box += "#{left}┃ #{prefix}#{password_string} ┃\n"
      box += "#{left}┃#{' ' * (min_width + 2)}┃\n"
      box += "#{left}┃ #{buttons} ┃\n"
      box += "#{left}┗#{'━' * (min_width + 2)}┛\n"

      cursor_top = offset_top + (config[:mode] == :password ? 4 : 6)
      cursor_left = offset_left
      case config[:mode]
      when :ok
        cursor_left += third / 2
      when :cancel
        cursor_left += min_width - third + third / 2 - 2
      else
        cursor_left += prefix.length + pw_length + 2
      end

      [box, config[:map], [cursor_top, cursor_left]]
    end

    def get_vault(vault_path = nil)
      return vault_path if vault_path
      path = File.expand_path CONFIG_PATH
      raise 'Config file missing, please log in' unless File.exist? path

      config = File.read path
      raise 'Config file error' unless config.start_with? 'path='
      config[5..-1].strip
    end

    def show(query, reply_type)
      item = @vault.find(/#{query}/i).first
      data = @vault.item_overview item
      unless %i( uuid url title ).include? reply_type
         data.merge!(@vault.item_detail item)
      end

      case reply_type
      when *%i( uuid url title )
        data[reply_type.to_s]
      when :username
        data['fields'].find({}) { |field| field['designation'] == 'username' }['value']
      when :password
        data['fields'].find({}) { |field| field['designation'] == 'password' }['value']
      else
        data
      end
    end

    def search(query)
      @vault.find(/#{query}/i).collect do |item|
        data = (@vault.item_overview item).merge(@vault.item_detail item)
        {
          uuid: data['uuid'],
          title: data['title'],
          username: data['fields'].find({}) { |field| field['designation'] == 'username' }['value']
        }
      end
    end

    def self.save(vault_path = nil)
      app = self.new vault_path # if succeeds, path & pw is good
      path = File.expand_path CONFIG_PATH
      File.open path, File::CREAT|File::TRUNC|File::RDWR do |file|
        file.write "path=#{File.expand_path vault_path}\n"
      end
    end

    def self.forget
      path = File.expand_path CONFIG_PATH
      File.delete path if File.exist? path
    end
  end
end
