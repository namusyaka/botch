$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

module Botch
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

      it "client should be a Client::Mechanize instance." do
        expect(SampleBotch.client).to be_an_instance_of(Botch::Client::MechanizeClient)
      end
    end

    describe "instance variable" do
      before(:all) do
        class SampleBotch < Botch::Base
          set :user_agent, "SampleBotch User-Agent"
          set :disabled_invalid, false

          filter(:all) { @test = "test" }
          rule(:all) { @test }
        end
      end

      it "should be able to use instance variable." do
        expect(SampleBotch.run(@fake.url)[0]).to eq("test")
      end
    end
  end
end
