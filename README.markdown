# OnePass

1Password command line client

## Installation


```ruby
gem install one_pass
```

## Usage

```
$ one-pass
Commands:
  one-pass --version, -v                           # Print the current version
  one-pass help [COMMAND]                          # Describe available commands or one specific command
  one-pass list FOLDER                             # List the contents of a folder, shows title and username
  one-pass login -v, --vault=Specify a vault path  # Save a 1Password vault and verify password
  one-pass logout                                  # Forget any saved 1Password vault
  one-pass search QUERY                            # Perform fuzzy search for items in your vault, shows uuid, title and username
  one-pass show [type] {NAME|UUID}                 # Get a single item from your vault, use only one type
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, commit, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sethvoltz/one_pass.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Todo

* [ ] Check for prerequisite external applications before calling them (pinentry, pbcopy)
* [ ] Detect OS to use appropriate clipboard utility
