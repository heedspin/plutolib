# -*- encoding: utf-8 -*-

# Thank you: http://yehudakatz.com/2010/04/02/using-gemspecs-as-intended/

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
require 'plutolib/version'

Gem::Specification.new do |s|
  s.name = "plutolib"
  s.version = Plutolib::VERSION

  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Tim Harrison"]
  s.email       = ["heedspin@gmail.com"]
  s.homepage    = "http://github.com/heedspin/plutolib"
  s.summary     = "The best way to manage your application's dependencies"
  s.summary     = "A dwarf library to do my bidding"
  s.description = "Code that's shared between many of my projects"
 
  s.required_rubygems_version = ">= 1.3.6"
 
  s.files        = Dir.glob("{bin,lib}/**/*") + %w(LICENSE-MIT README.md)
  s.require_path = 'lib'
end

