# coding: utf-8
Gem::Specification.new do |spec|
  # Project version
  spec.version                      = "0.3.4"

  # Project description
  spec.name                         = "bmc-daemon-lib"
  spec.authors                      = ["Bruno MEDICI"]
  spec.email                        = "bmc-daemon-lib@bmconseil.com"
  spec.description                  = "Shared utilities to build a daemon: logger, configuration, helpers"
  spec.summary                      = spec.description
  spec.homepage                     = "http://github.com/bmedici/bmc-daemon-lib"
  spec.licenses                     = ["MIT"]
  spec.date                         = Time.now.strftime("%Y-%m-%d")

  # List files and executables
  spec.files                        = `git ls-files -z`.split("\x0")
  spec.executables                  = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths                = ["lib"]
  spec.required_ruby_version        = ">= 2.2.2"

  # Development dependencies
  spec.add_development_dependency   "bundler", "~> 1.6"
  spec.add_development_dependency   "rake"
  spec.add_development_dependency   "rspec"
  spec.add_development_dependency   "rubocop"


  # Runtime dependencies
  spec.add_runtime_dependency       "chamber", "~> 2.9"
  spec.add_runtime_dependency       "newrelic_rpm"
  spec.add_runtime_dependency       "rollbar"
end
