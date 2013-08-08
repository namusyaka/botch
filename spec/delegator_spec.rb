$:.unshift(File.dirname(__FILE__))
require 'spec_helper'
require File.expand_path("../../lib/botch/main", __FILE__)


class DelegatorTest
  class Dummy
    attr_reader :result

    def method_missing(*args, &block)
      @result = args
      @result << block if block_given?
    end
  end

  def self.delegate_test(*args)
    args.each do |name|
      describe "delegate #{name}" do
        before(:all) { @fake = Botch::Fake.new }

        it "#{name}" do
          result = DelegatorTest.dummy { send(name) }.result
          expect(result).to eq([name])
        end

        it "#{name} with arguments" do
          fake = @fake
          result = DelegatorTest.dummy { send(name, fake.url) }.result
          expect(result).to eq([name, "http://example.com/"])
        end

        it "#{name} with block" do
          fake, block = @fake, proc {}
          result = DelegatorTest.dummy { send(name, fake.url, &block) }.result
          expect(result).to eq([name, "http://example.com/", block])
        end
      end
    end
  end

  def self.dummy(&block)
    dummy = Dummy.new
    Botch::Delegator.target = dummy
    Object.new.extend(Botch::Delegator).instance_eval(&block)
    Botch::Delegator.target
  end

  delegate_test :filter, :get, :helpers, :options, :post, :reset,
                :request, :rule, :run, :set, :settings
end
