# Botch

Botch is a simple DSL for quickly creating web crawlers.

Inspired by Sinatra.

## Installation

add this line to your Gemfile.

`gem 'botch'`

or

`$ gem install botch`

## Usage

```ruby
require 'lib/botch'
require 'kconv'

class SampleBotch < Botch::Base
  set :user_agent, "SampleBotch"

  filter(:all) { status == 200 }
  rule(:all) { |response| body.toutf8 }
end

if $0 == __FILE__
  SampleBotch.run("http://namusyaka.info/") do |response|
    puts response
  end
end
```

## TODO

- RSpec
- GET/POST method
- Documentation
- Classic style

## Contributing to Botch

1. fork the project.
2. create your feature branch. (`git checkout -b my-feature`)
3. commit your changes. (`git commit -am 'commit message.'`)
4. push to the branch. (`git push origin my-feature`)
5. send pull request.

## License

MIT

