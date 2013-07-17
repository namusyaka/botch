$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

module Botch
  describe Filter do
    before(:each) do
      FakeWeb.clean_registry
      @fakes = []
      @fakes << Fake.new("/", :status => [200, "OK"], :content_type => "text/html")
      @fakes << Fake.new("/test1", :status => [404, "Not Found"], :content_type => "text/html")
      @fakes << Fake.new("/test2", :status => [500, "Internal Server Error"], :content_type => "text/html")

      class SampleBotch < Botch::Base
        reset!
        set :client, :faraday
        filter :test1, :map => /test1|test2/ do
          status == 404
        end
      end
    end

    it "filter should decide a valid in reference to return value of filter's block." do
      result = SampleBotch.run(*@fakes.map(&:url)) {|response, valid| valid }
      expect(result[0]).to be_true
      expect(result[1]).to be_true
      expect(result[2]).to be_false
    end
  end
end
