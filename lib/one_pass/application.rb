require 'io/console'
require 'dispel'

module OnePass
  # OnePass CLI
  class Application
    def initialize(vault_path)
      @vault_path = vault_path
    end

    def run
      opvault = OpVault.new @vault_path

      print 'Type your password: '
      master_password = STDIN.noecho(&:gets).chomp
      puts

      opvault.unlock master_password
      opvault.load_items
    end

    def test_item
      # Test Code
      item = opvault.find(/^2/).first

      print 'Decrypting item overview... '
      overview = opvault.item_overview item
      puts '[ DONE ]'
      puts JSON.pretty_generate(overview)

      print 'Decrypting item detail... '
      detail = opvault.item_detail item
      print '[ DONE ]'
      puts JSON.pretty_generate(detail)
    end
  end
end
