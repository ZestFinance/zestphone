require 'spec_helper'

describe 'Answering a call' do
  before do
    @existing_whitelist = Telephony.whitelist
    phone_number = '562-555-5555'
    Telephony.whitelist = [phone_number]

    agent = create :agent
    @call = create :connecting_call, agent: agent
    @participant = create :call,
      number: phone_number,
      conversation: @call.conversation

    post "/zestphone/providers/twilio/calls/#{@call.id}/connect"
  end

  after do
    Telephony.whitelist = @existing_whitelist
  end

  it "updates the conversation's customer's state to 'connecting'" do
    @participant.reload
    @participant.state.should == 'connecting'
  end

  it 'returns TwiML for calling the callee' do
    xml = Nokogiri::XML response.body
    dial = xml.at('/Response/Dial')
    dial.attributes['action'].value.should == "/zestphone/providers/twilio/calls/#{@call.id}/child_detached"
    dial.attributes['record'].value.should == 'true'
    number = dial.at('Number')
    number.attributes['url'].value.should == "/zestphone/providers/twilio/calls/#{@participant.id}/child_answered"
    number.text.should == @participant.number
  end
end

describe 'Answering a call to a non-whitelisted number' do
  before do
    @existing_whitelist = Telephony.whitelist
    Telephony.whitelist = []
    agent = create :agent
    @call = create :connecting_call, agent: agent
    create :participant,
      conversation: @call.conversation

    post "/zestphone/providers/twilio/calls/#{@call.id}/connect"
  end

  after do
    Telephony.whitelist = @existing_whitelist
  end

  it 'returns TwiML that includes a message about the callee not being whitelisted' do
    xml = Nokogiri::XML response.body
    say = xml.at('/Response/Say')
    say.text.should =~ /The number you are trying to call is not whitelisted/i
  end
end
