$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

module Botch
  describe do
    it "Should have a version." do
      expect(Botch.const_defined?("VERSION")).to be_true
    end
  end

  describe Base do
    before(:all) do
      @fake = Fake.new
      class SampleBotch < Botch::Base; end
      SampleBotch.run(@fake.url) {}
    end

    it 'Default client should be faraday.' do
      expect(SampleBotch.client).to be_an_instance_of(Botch::Client::FaradayClient)
    end

    describe "settings and options" do
      before(:all) do
        class SampleBotch < Botch::Base
          set :user_agent, "SampleBotch User-Agent"
          set :client, :mechanize
          set :disabled_invalid, true
          set :original_option, "foobar"
        end
        @options  = SampleBotch.options
        @settings = SampleBotch.settings
      end

      it "Original options should be stored in options." do
        expect(@options[:original_option]).to eq("foobar")
      end

      it ":user_agent should be stored in options." do
        expect(@options[:user_agent]).to eq("SampleBotch User-Agent")
      end

      it ":disabled_invalid should be stored in settings." do
        expect(@settings[:disabled_invalid]).to be_true
      end

      it "Client setter should be valid." do
        expect(SampleBotch.client).to be_an_instance_of(Botch::Client::MechanizeClient)
      end
    end
  end
end
