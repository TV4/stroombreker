# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stroombreker/version'

Gem::Specification.new do |spec|
  spec.name          = "stroombreker"
  spec.version       = Stroombreker::VERSION
  spec.authors       = ["Patrik Stenmark"]
  spec.email         = ["patrik@stenmark.io"]
  spec.description   = %q{An implementation of the circuit breaker pattern}
  spec.summary       = %q{An implementation of the circuit breaker pattern}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry", "~> 0.9.12"
  spec.add_development_dependency "timecop", "~> 0.7.1"
  spec.add_development_dependency "activesupport"
end
