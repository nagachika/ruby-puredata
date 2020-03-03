# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'puredata/version'

Gem::Specification.new do |spec|
  spec.name          = "puredata"
  spec.version       = Puredata::VERSION
  spec.authors       = ["CHIKANAGA Tomoyuki"]
  spec.email         = ["nagachika00@gmail.com"]

  spec.summary       = "Ruby library to manipulate PureData (Pd-extended) via socket."
  spec.description   = "Ruby library to manipulate PureData (Pd-extended) via socket."
  spec.homepage      = "https://github.com/nagachika/ruby-puredata"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]
end
