require 'io/console'
require 'thor'

require 'OnePass/application'

module OnePass
  # OnePass CLI
  class CLI < Thor
    SHOW_OPTIONS = %w( all username password url uuid title )

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
    SHOW_OPTIONS.each do |switch|
      option switch.to_sym, type: :boolean
    end
    def show(name)
      # Check for multiple mutex args
      type = SHOW_OPTIONS.each_with_object(Hash.new) do |k, hash|
        hash[k] = options[k] if options.has_key?(k)
      end
      if type.length > 1
        puts "Use only one of #{SHOW_OPTIONS.collect { |switch| '--' + switch }.join ', '}"
        exit 1
      end

      # TODO: Check if name looks like a UUID
      # otherwise, search for title by substring, return first
      app = OnePass::Application.new
      app.show name, type.keys.first.to_sym
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
