# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "urlybird/version"

Gem::Specification.new do |s|
  s.name        = "urlybird"
  s.version     = UrlyBird::VERSION
  s.authors     = ["Kriselda Rabino", "Jim Myhrberg"]
  s.email       = ["kriselda.rabino@gmail.com", "contact@jimeh.me"]
  s.homepage    = "http://rubygems.org/gems/urlybird"
  s.summary     = "UrlyBird fetches all your URIs in one fell swoop"
  s.description = 'Send UrlyBird off into the intricate canopies of your ' +
                  'URI-inhabited content, and watch him bring you ' +
                  'back a beakful of Addressable::URI objects ' +
                  'to do with what you will.'

  s.files      = Dir['lib/**/*']
  s.test_files = Dir['spec/**/*']

  s.add_development_dependency "rspec", ">= 2.8.0"
  s.add_development_dependency "simplecov", ">= 0"

  s.add_runtime_dependency "addressable", ">= 2.2.7"
end
