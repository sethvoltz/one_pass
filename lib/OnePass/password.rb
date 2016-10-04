require 'ttyname'

module OnePass
  # Fork out to `pinentry` for password
  class Password
    DESCRIPTION = 'Please enter your 1Password master password for the following vault:'.freeze
    DEFAULT = {
      title: '1Password CLI',
      prompt: 'Master Password: '
    }.freeze

    def initialize(opts = {})
      @config = OpenStruct.new DEFAULT.merge(opts)
      if @config.vault_path
        @config.description ||= "#{DESCRIPTION}%0a#{@config.vault_path}"
      end
    end

    def prompt(error_message = nil)
      @config.error = error_message
      @pipe = IO.popen 'pinentry', 'r+'
      check
      send_settings
      fetch_password
      @password
    end

    def done
      send 'BYE'
      @pipe.close
    end

    private

    def send_settings
      command 'SETTITLE', @config.title
      command 'SETPROMPT', @config.prompt
      command 'SETERROR', @config.error if @config.error
      command 'SETDESC', @config.description

      option 'ttytype', ENV['TERM']
      option 'ttyname', $stdin.ttyname
      option 'display', ENV['DISPLAY']
    end

    def fetch_password
      @password = ''
      send 'GETPIN'
      loop do
        case response = @pipe.gets
        when /^D .*/ then @password = response[2..-1].chomp
        when /^OK/ then break
        else
          @password = nil
          break
        end
      end
    rescue Interrupt
      @password = nil
    end

    def command(command, option = nil)
      send command, option
      check
    end

    def option(name, value)
      command 'OPTION', "#{name}=#{value}"
    end

    def send(command, option = nil)
      @pipe.puts "#{command}#{option ? ' ' + option : ''}"
    end

    def check
      response = @pipe.gets
      raise 'bad response' unless response.start_with? 'OK'
    end
  end
end
