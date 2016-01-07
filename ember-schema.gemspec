# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ember/schema/version'

Gem::Specification.new do |spec|
  spec.name          = "ember-schema"
  spec.version       = Ember::Schema::VERSION
  spec.authors       = ["Nathan Palmer", "Aaron Hansen"]
  spec.email         = ["nathan@nathanpalmer.com"]
  spec.summary       = %q{Generates a json schema for restpack_serializer models}
  # spec.description   = %q{TODO: Write a longer description. Optional.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
