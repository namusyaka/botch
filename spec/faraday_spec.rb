$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

module Botch
  describe Client::FaradayClient do
    before(:all) do
      FakeWeb.clean_registry
      @fakes = []
      @fakes << Fake.new("/", :status => [200, "OK"], :content_type => "text/html")
      @fakes << Fake.new("/test1", :status => [404, "Not Found"], :content_type => "text/html")
      @fakes << Fake.new("/test2", :status => [500, "Internal Server Error"], :content_type => "text/html")

      class SampleBotch < Botch::Base
        set :user_agent, "SampleBotch User-Agent"
        set :client, :faraday
        set :disabled_invalid, nil
        filter(:all){ status == 200 }
        rule(:all){ status }
      end
    end

    it 'client should be faraday if set :faraday to :client.' do
      expect(SampleBotch.run(@fakes[0].url) { client }[0]).to be_an_instance_of(Botch::Client::FaradayClient)
    end

    it 'helpers should return valid data.' do
      result = SampleBotch.run(@fakes[0].url) do
        { :status => status, :header => header, :body => body }
      end
      result = result[0]
      expect(result[:status]).to eq(200)
      expect(result[:header]).to be_an_instance_of(Faraday::Utils::Headers)
      expect(result[:body]).to be_an_instance_of(String)
    end

    it 'block argument of #rule should replace last expression.' do
      result = SampleBotch.run(*@fakes.map(&:url))
      expect(result[0]).to eq(200)
      expect(result[1]).to eq(404)
      expect(result[2]).to eq(500)
    end

    it 'block argument of #run should replace last expression.' do
      result = SampleBotch.run(*@fakes.map(&:url)){ "Foo" }
      expect(result[0]).to eq("Foo")
      expect(result[1]).to eq("Foo")
      expect(result[2]).to eq("Foo")
    end

    it 'the second argument should be boolean.' do
      result = SampleBotch.run(*@fakes.map(&:url)){ |response, valid| valid }
      expect(result[0]).to be_true
      expect(result[1]).to be_false
      expect(result[2]).to be_false
    end
  end
end
