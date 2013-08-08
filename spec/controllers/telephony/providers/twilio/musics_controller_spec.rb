require "spec_helper"

module Telephony
  describe Providers::Twilio::MusicsController do
    before { @routes = Engine.routes }

    describe "#hold" do
      before do
        get :hold
      end

      it "returns TwiML for playing hold music" do
        xml = Nokogiri::XML response.body
        play = xml.at('/Response/Play')

        play.text.should == "https://example.com/hold_music.wav"
      end
    end
  end
end
