require 'io/console'
require 'dispel'

module OnePass
  # OnePass CLI
  class Application
    def initialize(vault_path)
      @vault_path = vault_path
    end

    def run
      @vault = OpVault.new @vault_path

      @vault.unlock do
        print 'Type your password: '
        master_password = STDIN.noecho(&:gets).chomp
        puts
        master_password
      end
      @vault.load_items

      test_item
    end

    def test_item
      # Test Code
      item = @vault.find(/^2/).last

      print 'Decrypting item overview... '
      overview = @vault.item_overview item
      puts '[ DONE ]'
      puts JSON.pretty_generate(overview)

      print 'Decrypting item detail... '
      detail = @vault.item_detail item
      print '[ DONE ]'
      puts JSON.pretty_generate(detail)
    end
  end
end
