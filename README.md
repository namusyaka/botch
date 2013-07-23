# Botch

Botch is a simple DSL for quickly creating web crawlers.

Inspired by Sinatra.

[Japanese](https://gist.github.com/namusyaka/6001467)

## Installation

add this line to your Gemfile.

`gem 'botch'`

or

`$ gem install botch`

## Usage

```ruby
require 'lib/botch'
require 'kconv'
require 'rack'

class SampleBotch < Botch::Base
  set :user_agent, "SampleBotch"

  helpers do
    def h(str)
      Rack::Utils.escape_html(str)
    end
  end

  filter :example, :map => "example.com" do
    status == 200
  end

  rule :example, :map => /example\.com/ do
    h(body.toutf8)
  end
end

if $0 == __FILE__
  SampleBotch.run("http://example.com/") do |response|
    puts response
  end
end
```

## TODO

- RSpec
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

