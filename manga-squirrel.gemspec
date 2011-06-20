# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "manga-squirrel/version"

Gem::Specification.new do |s|
  s.name        = "manga-squirrel"
  s.version     = Manga::Squirrel::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Erol Fornoles","Ali Lown"]
  s.email       = ["erol.fornoles@gmail.com","ali@lown.me.uk"]
  s.homepage    = "http://rubygems.org/gems/manga-squirrel"
  s.summary     = %q{Manga Squirrel: Manga Fox Mass Downloader}
  s.description = %q{Manga Squirrel is a background multi-threaded mass downloader for the site Manga Fox using Ruby + Redis + Resque.}

  s.rubyforge_project = "manga-squirrel"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "nokogiri"
  s.add_dependency "resque"
  s.add_dependency "thor"
  s.add_dependency "rubyzip"
end
