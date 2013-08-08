require 'botch'

module Botch
  module Delegator
    class << self
      def delegate(*methods)
        methods.each do |method_name|
          define_method(method_name) do |*args, &block|
            Delegator.target.send(method_name, *args, &block)
          end
        end
      end

      def target
        @target ||= Main
      end

      def target=(klass)
        @target = klass
      end
    end

    delegate :filter, :get, :helpers, :options, :post, :reset,
             :request, :rule, :run, :set, :settings
  end

  class Main < Base; end
end

extend Botch::Delegator
