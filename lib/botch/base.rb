require 'rubygems' unless defined?(Gem)
require 'faraday'
require 'mechanize'

%w(
  clients/abstract_client
  clients/faraday_client
  clients/mechanize_client
).each{ |path| require File.expand_path("../#{path}", __FILE__)  }

module Botch
  class Route
    attr_accessor :routes

    def initialize
      @routes = []
      self
    end

    def add(label, options = {}, &block)
      raise ArgumentError unless block_given?
      if position = index(label)
        route = @routes[position]
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
      !!index(label)
    end

    alias :exists? :exist?

    def index(label)
      @routes.index{ |route| route[:label] === label }
    end

    def inject(url)
      @routes.inject([]) do |result, route|
        result << route if map_validation(url, route[:map])
        result
      end
    end

    private

    def map_validation(url, map)
      case map.class.to_s
      when "Regexp" then url =~ map
      when "String" then url.include?(map)
      else               true
      end
    end
  end

  %w( Filter Rule ).each { |klass| Object.const_set(klass, Class.new(Route)) }

  class Base
    DEFAULT_INSTANCE_VARIABLES = { :header => nil, :body => nil, :status => nil }
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

      def generate_wrapper(&method)
        method.arity != 0 ? proc {|args| method.call(*args) } :
                            proc {|args| method.call }
      end

      def generate_method(method_name, &block)
        define_method(method_name, &block)
        unbound_method = instance_method(method_name)
        remove_method(method_name)
        unbound_method
      end

      def reset!
        settings = {}
      end

      def run(*urls, &block)
        if block_given?
          unbound_method = generate_method(:main_unbound_method, &block).bind(instance)
          block = case unbound_method.arity
                  when 2 then proc{|r,v| unbound_method.call(r, v) }
                  when 1 then proc{|r,v| unbound_method.call(r) }
                  else        proc{|r,v| unbound_method.call }
                  end
        end
        set_default_options! unless self.client

        urls.map do |url|
          filters, rules = @@routes.map{ |k, v| v.inject(url) }
          response = self.client.get(url, options)

          set_instance_variables(:header => response[:header],
                                 :body   => response[:body],
                                 :status => response[:status])

          response = response[:response]

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

        def set_default_options!
          self.client = :faraday
        end
    end
  end
end