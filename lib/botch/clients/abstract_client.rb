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
    end
  end
end
