# coding: utf-8
Gem::Specification.new do |spec|
  # Project version
  spec.version                      = "0.9.0"

  # Project description
  spec.name                         = "bmc-daemon-lib"
  spec.authors                      = ["Bruno MEDICI"]
  spec.email                        = "opensource@bmconseil.com"
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
  spec.add_development_dependency   "bundler"
  spec.add_development_dependency   "rake"
  spec.add_development_dependency   "rspec"
  spec.add_development_dependency   "rubocop"
  #spec.add_development_dependency   "pry"

  # Runtime dependencies
  # spec.add_runtime_dependency       "hashie" , "~> 3.4.6"   # upgrading to 3.5.4 breaks things !
  # spec.add_runtime_dependency       "chamber" , "~> 2.9.1"

  spec.add_runtime_dependency       "hashie" , "~> 3.4.6"   # upgrading to 3.5.4 breaks things !
  spec.add_runtime_dependency       "chamber"
end
