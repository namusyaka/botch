module Botch
  module Client
    class AbstractClient
      attr_reader :client

      def initialize
        @client = nil
      end

      def get(url, options = {})
        # return a response object
      end

      def post(url, options = {})
      end
    end
  end
end
