require 'rubygems' unless defined?(Gem)
require 'faraday'
require 'mechanize'

%w(
  abstract
  faraday
  mechanize
).each{ |path| require File.expand_path("../clients/#{path}_client", __FILE__)  }

module Botch
  class Route
    attr_accessor :routes

    def initialize
      @routes = []
    end

    def add(label, options = {}, &block)
      raise ArgumentError unless block_given?
      if route = exists?(label)
        route[:block] = block
        route[:label] = label
      else
        options[:block] = block
        options[:label] = label
        @routes << options
      end
    end

    def del(label)
      @routes.delete_if{ |route| route[:label] == label }
    end

    def exist?(label)
      @routes.find{ |route| route[:label] == label }
    end

    alias exists? exist?

    def inject(url)
      @routes.inject([]) do |result, route|
        result << route if map_validation(url, route[:map])
        result
      end
    end

    private

    def map_validation(url, map)
      case map
      when Regexp   then url =~ map
      when String   then url.include?(map)
      when NilClass then true
      else               nil
      end
    end
  end

  %w( Filter Rule ).each { |klass| Object.const_set(klass, Class.new(Route)) }

  class Base
    DEFAULT_INSTANCE_VARIABLES = { :header => nil, :body => nil, :status => nil, :url => nil }
    attr_reader(*DEFAULT_INSTANCE_VARIABLES.keys)

    def initialize
      @header, @body = nil, nil
    end

    def client
      self.class.client
    end

    def options
      self.class.options
    end

    def settings
      self.class.settings
    end

    class << self
      @@routes = { :filter => Filter.new, :rule => Rule.new }

      attr_reader :client

      def instance
        @instance ||= self.new
      end

      def helpers(*extensions, &block)
        class_eval(&block) if block_given?
        include(*extensions) if extensions.any?
      end

      def set(key, value = nil)
        return __send__("#{key}=", value) if respond_to?("#{key}=")

        key_symbol = key.to_sym
        return settings[key_symbol] = value if settings.has_key?(key_symbol)

        options[key_symbol] = value
      end

      def route(type, label, options = {}, &block)
        unbound_method = generate_method("#{type} #{label}", &block).bind(instance)
        wrapper = generate_wrapper(&unbound_method)

        @@routes[type.to_sym].add(label, options, &wrapper)
      end

      def filter(label, options = {}, &block)
        route(:filter, label, options, &block)
      end

      def rule(label, options = {}, &block)
        route(:rule, label, options, &block)
      end

      def generate_wrapper(&block)
        block.arity != 0 ? proc {|args| block.call(*args) } :
                           proc {|args| block.call }
      end

      def generate_method(method_name, &block)
        define_method(method_name, &block)
        unbound_method = instance_method(method_name)
        remove_method(method_name)
        unbound_method
      end

      def generate_main_block(&block)
        unbound_method = generate_method(:main_unbound_method, &block).bind(instance)
        case unbound_method.arity
        when 2 then proc{|r,v| unbound_method.call(r,v) }
        when 1 then proc{|r,v| unbound_method.call(r) }
        else        proc{|r,v| unbound_method.call }
        end
      end

      def reset
        @@routes = { :filter => Filter.new, :rule => Rule.new }
      end

      def reset!
        reset
        settings = {}
      end

      def request(method, *urls, &block)
        set_default_options  unless self.client
        raise ArgumentError  unless self.client.respond_to?(method)

        block = generate_main_block(&block) if block_given?

        urls.map do |url|
          filters, rules = @@routes.map{ |k, v| v.inject(url) }
          response = self.client.send(method, url, options)

          set_instance_variables :header => response[:header],
                                 :body   => response[:body],
                                 :status => response[:status],
                                 :url    => url

          response = response[:response]
          valid    = true

          unless filters.empty?
            valid = filters.map{ |_filter| _filter[:block].call(response) }.all?
            next if settings[:disabled_invalid] && !valid
          end

          response = rules.inject(nil) { |result, _rule|
            _rule[:block].call((result || response))
          } unless rules.empty?

          response = block.call(response, valid) if block_given?
          set_instance_variables(DEFAULT_INSTANCE_VARIABLES)
          response
        end
      end

      def get(*urls, &block); request(:get, *urls, &block); end
      def post(*urls, &block); request(:post, *urls, &block); end

      alias run get

      def client=(name)
        @client = Client.const_get("#{name.to_s.capitalize}Client").new(settings) if clients.include?(name)
      end

      def settings
        @settings ||= { :disabled_invalid => false }
      end

      def options
        @options ||= {}
      end

      private

        def set_instance_variables(pairs = {})
          pairs.each_pair { |name, value| instance.instance_variable_set("@#{name}".to_sym, value) }
        end

        def clients
          @_clients ||= [:faraday, :mechanize]
        end

        def set_default_options
          self.client = :faraday
        end
    end
  end
end
