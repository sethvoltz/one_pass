# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'OnePass/version'

Gem::Specification.new do |spec|
  spec.name          = "one_pass"
  spec.version       = OnePass::VERSION
  spec.authors       = ["Seth Voltz"]
  spec.email         = ["seth@designgods.net"]

  spec.summary       = "A simple command line client for your 1Password vault"
  spec.description   = "Retrieve passwords from your 1Password OpVault-encoded vault via the command line"
  spec.homepage      = "https://sethvoltz.github.com/one_pass"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "dispel", "~> 0.0"
  spec.add_runtime_dependency 'curses', '~> 1'
  spec.add_runtime_dependency "thor", "~> 0.19"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "bump", "~> 0.5"
end
