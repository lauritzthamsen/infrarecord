# -*- encoding: utf-8 -*-
require File.expand_path('../lib/infrarecord/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Freenerd"]
  gem.email         = ["nospam@freenerd.de"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = Dir["{lib}/**/*", "{app}/**/*", "{public}/**/*", "{config}/**/*"]
  gem.name          = "infrarecord"
  gem.require_paths = ["lib"]
  gem.version       = Infrarecord::VERSION
  gem.add_dependency "ruby_parser"
  gem.add_dependency "ruby2ruby"
end
