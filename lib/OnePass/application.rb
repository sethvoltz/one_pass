# require 'dispel'

module OnePass
  # OnePass Application
  class Application
    CONFIG_PATH='~/.one_pass'

    def initialize(vault_path = nil)
      @vault_path = get_vault vault_path
      @vault = OpVault.new @vault_path

      @vault.unlock do
        print 'Type your password: '
        master_password = STDIN.noecho(&:gets).chomp
        puts
        master_password
      end
      @vault.load_items
    end

    def get_vault(vault_path = nil)
      return vault_path if vault_path
      path = File.expand_path CONFIG_PATH
      raise 'Config file missing, please log in' unless File.exist? path

      config = File.read path
      raise 'Config file error' unless config.start_with? 'path='
      config[5..-1].strip
    end

    def show(search, reply_type)
      item = @vault.find(/#{search}/i).first

      print 'Decrypting item overview... '
      overview = @vault.item_overview item
      puts '[ DONE ]'
      puts JSON.pretty_generate(overview)

      print 'Decrypting item detail... '
      detail = @vault.item_detail item
      print '[ DONE ]'
      puts JSON.pretty_generate(detail)
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
