require 'English'

module OnePass
  # OnePass Application
  class Application
    CONFIG_PATH = '~/.one_pass'.freeze

    def initialize(vault_path = nil)
      @vault_path = get_vault vault_path
      @vault = OpVault.new @vault_path

      check_for_dependencies
      prompter = OnePass::Password.new(vault_path: @vault_path)
      password_loop prompter
    ensure
      prompter && prompter.done
    end

    def check_for_dependencies
      unless installed? 'pinentry --version'
        puts 'Please install the `pinentry` program.'
        puts '  on macOS, we recommend using Homebrew: `brew install pinentry`.'
        exit 127
      end
    end

    def password_loop(prompter)
      error_message = nil
      loop do
        password = prompter.prompt error_message
        exit if password.nil? # cancelled
        begin
          @vault.unlock password
          @vault.load_items
          break
        rescue => error
          error_message = error.message
          next
        end
      end
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
        data.merge!(@vault.item_detail(item))
      end

      case reply_type
      when %i( uuid url title )
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
        data = (@vault.item_overview item).merge(@vault.item_detail(item))
        {
          uuid: data['uuid'],
          title: data['title'],
          username: data['fields'].find({}) do |field|
            field['designation'] == 'username'
          end['value']
        }
      end
    end

    def installed?(program)
      `#{program}`
      result = $CHILD_STATUS
      result.exitstatus != 127
    end

    def self.save(vault_path = nil)
      new vault_path # if succeeds, path & pw is good
      path = File.expand_path CONFIG_PATH
      File.open path, File::CREAT | File::TRUNC | File::RDWR do |file|
        file.write "path=#{File.expand_path vault_path}\n"
      end
    end

    def self.forget
      path = File.expand_path CONFIG_PATH
      File.delete path if File.exist? path
    end
  end
end
