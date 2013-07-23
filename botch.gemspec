require File.expand_path("../lib/botch/version", __FILE__)

Gem::Specification.new "botch", Botch::VERSION do |s|
  s.description      = "Botch is a DSL for quickly creating web crawlers. Inspired by Sinatra."
  s.summary          = "A DSL for web clawler."
  s.authors          = ["namusyaka"]
  s.email            = "namusyaka@gmail.com"
  s.homepage         = "https://github.com/namusyaka/botch"
  s.files            = `git ls-files`.split("\n") - %w(.gitignore)
  s.test_files       = s.files.select { |path| path =~ /^spec\/.*_spec\.rb/ }
  s.license          = "MIT"

  s.add_dependency "faraday"
  s.add_dependency "mechanize"
  s.add_development_dependency "rspec"
  s.add_development_dependency "fakeweb", ["~> 1.3"]
end
