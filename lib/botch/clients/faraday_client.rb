module Botch
  module Client
    class FaradayClient < AbstractClient
      def initialize(settings = {})
        @client     = :faraday
        @handler    = Faraday.new(settings) do |builder|
          builder.use Faraday::Adapter::NetHttp
          builder.use Faraday::Request::UrlEncoded
        end
      end

      def get(url, options = {})
        options.each_pair{ |key, value| @handler.headers[key] = value }
        response = @handler.get(url)
        parse_response(response)
      end

      def post(url, options = {})
        options.each_pair{ |key, value| @handler.headers[key] = value }
        response = @handler.post(url)
        parse_response(response)
      end

      def parse_response(response)
        result = {}
        result[:status]   = response.status
        result[:header]   = response.headers
        result[:body]     = response.body
        result[:response] = response
        result
      end
    end
  end
end
