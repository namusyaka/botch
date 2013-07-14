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

      def parse_response(response)
        result = {}
        result[:header]   = response.header
        result[:status]   = response.code.to_i
        result[:body]     = response.body
        result[:response] = response
        result
      end
    end
  end
end
