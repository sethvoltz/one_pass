require 'io/console'
require 'thor'

require 'OnePass/application'

module OnePass
  # OnePass CLI
  class CLI < Thor
    desc 'login', 'Save a 1Password vault and verify password'
    option :vault, aliases: '-v', type: :string, banner: 'Specify a vault path'
    def login
      OnePass::Application.save options.vault
    end

    desc 'logout', 'Forget any saved 1Password vault'
    def logout
      OnePass::Application.forget
    end

    desc 'show [type] {NAME|UUID}', 'Get a single item from your vault, use only one type'
    option :clip, aliases: '-c', type: :boolean, banner: 'Copy value to clipboard instead of stdout'
    option :all, type: :boolean
    option :username, type: :boolean
    option :password, type: :boolean
    option :url, type: :boolean
    option :uuid, type: :boolean
    option :title, type: :boolean
    def show(name)
      # Check for multiple mutex args
      # if options[:list] && options[:file]
      #   puts "Use only one, --list(-l) or --file(-f)"
      #   exit(0)
      # end
      type = 'password'

      # Check if name looks like a UUID
      # otherwise, search for title by substring, return first
      app = OnePass::Application.new
      app.show name, type
    end

    desc 'search QUERY', 'Perform fuzzy search for items in your vault, shows title and username'
    def search(query)
    end

    map ls: :list
    desc 'list FOLDER', 'List the contents of a folder, shows title and username'
    def list(folder)
    end
  end
end
