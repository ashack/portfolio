# frozen_string_literal: true

$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "navigation_engine/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "navigation_engine"
  spec.version     = NavigationEngine::VERSION
  spec.authors     = [ "Your Name" ]
  spec.email       = [ "your-email@example.com" ]
  spec.homepage    = "https://github.com/yourusername/navigation_engine"
  spec.summary     = "Flexible navigation system for Rails applications"
  spec.description = "A Rails engine that provides a configurable navigation system with YAML configuration, role-based visibility, and multiple rendering styles."
  spec.license     = "MIT"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 7.0"

  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "pry"
end
