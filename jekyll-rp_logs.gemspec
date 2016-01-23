# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "jekyll/rp_logs/version"

Gem::Specification.new do |spec|
  spec.name          = "jekyll-rp_logs"
  spec.version       = Jekyll::RpLogs::VERSION
  spec.authors       = ["anrodger"]
  spec.email         = ["me@andrew.rs"]

  if spec.respond_to?(:metadata)
    # spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com' to prevent pushes to rubygems.org, or delete to allow pushes to any server."
  end

  spec.summary       = %q(Jekyll plugin to turn raw IRC RP logs into pretty pages.)
  # spec.description   = %q(TODO: Write a longer description or delete this line.)
  spec.homepage      = "https://github.com/xiagu/jekyll-rp_logs"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|dev_site)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "nokogiri", "~> 1.6"
  spec.add_development_dependency "rspec", "~> 3"
  spec.add_development_dependency "simplecov", "~> 0.9"
  spec.add_development_dependency "codeclimate-test-reporter"

  spec.add_runtime_dependency "jekyll", "~> 2.5"
  spec.add_runtime_dependency "rake", "~> 10.0"
  spec.add_runtime_dependency "gli", "~> 2.13"

  spec.required_ruby_version = "~> 2.1"
end
