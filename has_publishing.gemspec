# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'has_publishing/version'

Gem::Specification.new do |gem|
  gem.name          = "has_publishing"
  gem.version       = HasPublishing::VERSION
  gem.authors       = ["Josh McArthur @ 3months"]
  gem.email         = ["joshua.mcarthur@gmail.com"]
  gem.description   = %q{Add ability to draft/publish/withdraw/embargo models}
  gem.summary       = %q{Add publishing to your ActiveRecord models}
  gem.homepage      = "https://github.com/3months/has_publishing"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "activerecord"
  gem.add_dependency "activesupport"
  gem.add_development_dependency "debugger"
  gem.add_development_dependency "rspec-rails"
  gem.add_development_dependency "sqlite3"
end
