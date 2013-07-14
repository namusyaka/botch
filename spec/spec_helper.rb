require 'botch'
require 'fakeweb'

FakeWeb.allow_net_connect = false

module Botch
  SPEC_DOMAIN = 'example.com'

  class Fake
    def initialize(path = "/", options = {})
      @path         = path
      @scheme       = options[:scheme] || "http"
      @content_type = options[:content_type] || "text/html"
      @status       = options[:status] || [200, "OK"]
      add_to_fakeweb
    end

    def url
      @scheme + "://" + SPEC_DOMAIN + @path
    end

    def body
      @body ||= <<-HTML
<html>
<head>
<title>Fake page #{@path}</title>
</head>
<body>
</body>
</html>
      HTML
    end

    def add_to_fakeweb
      options = { :body => @body, :content_type => @content_type, :status => @status }
      FakeWeb.register_uri(:get, url, options)
    end
  end
end
