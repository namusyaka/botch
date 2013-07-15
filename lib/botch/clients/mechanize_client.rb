require 'uri'

module Botch
  module Client
    class MechanizeResponseError
      attr_accessor :code, :header, :body

      def initialize(response_error)
        @code     = response_error.response_code
        @body     = ""
        @header   = Mechanize::Headers.new
        @response = response_error
      end
    end

    class MechanizeClient < AbstractClient
      def initialize(options = {})
        @client  = :mechanize
        @handler = Mechanize.new
      end

      def get(url, options = {})
        @handler.user_agent = options[:user_agent] if options[:user_agent]
        mechanize_page = @handler.get(url) rescue MechanizeResponseError.new($!)
        parse_response(mechanize_page)
      end

      def post(url, options = {})
        @handler.user_agent = options[:user_agent] if options[:user_agent]
        url, query = serialize_url(url)
        mechanize_page = @handler.post(url, query) rescue MechanizeResponseError.new($!)
        parse_response(mechanize_page)
      end

      private

      def parse_response(response)
        result = {}
        result[:header]   = response.header
        result[:status]   = response.code.to_i
        result[:body]     = response.body
        result[:response] = response
        result
      end

      def serialize_url(url)
        uri = URI.parse(url)
        serializable_url = []
        serializable_url[0] = "#{uri.scheme}://#{uri.host}#{uri.path}"
        serializable_url[1] = uri.query.split(/&/).map do |pair|
          pair = pair.split(/=/)
          pair << "" if pair.length == 1
          pair
        end
        serializable_url[1] = Hash[*serializable_url[1].flatten]
        serializable_url
      end
    end
  end
end
