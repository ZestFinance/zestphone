require 'spec_helper'

describe 'Enqueued calls wait music' do
  before do
    get '/zestphone/providers/twilio/inbound_calls/wait_music'
  end

  it 'returns TwiML for playing wait music' do
    xml = Nokogiri::XML response.body
    play = xml.at('/Response/Play')
    play.text.should =~ /\.wav$/
  end
end
