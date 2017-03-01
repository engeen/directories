$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "directories/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "directories"
  s.version     = Directories::VERSION
  s.authors     = [""]
  s.email       = [""]
  s.homepage    = "http://some.url"
  s.summary     = "Directories engine."
  s.description = "JQuery Datatables and DSL-like declarative engine for speeding up CRUD interfaces development."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib,vendor}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "4.2.6"
  s.add_dependency "chewy", "~> 0.8.4"
  s.add_dependency "aasm", "~> 4.11.1"
  s.add_dependency "cancancan", "~> 1.10"
  s.add_dependency 'less-rails', '>= 2.7.0'
  s.add_dependency 'less-rails-bootstrap', '~> 3.3.5.0'
  s.add_dependency 'bh', '~> 1.3.6'
  s.add_dependency 'lodash-rails', '~> 4.17.2'
  s.add_dependency 'audited', '~> 4.3'


  s.add_development_dependency "sqlite3"
end
