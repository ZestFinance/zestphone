require 'spec_helper'

describe 'The receiver answering the call' do
  before do
    conversation = create :conversation, state: :connecting
    agent = create :agent
    @call = create :call, sid: nil, state: :connecting,
      conversation: conversation, agent: agent
    @sid = 'sid123'

    post "/zestphone/providers/twilio/calls/#{@call.id}/child_answered",
      { CallSid: @sid }

    @call.reload
  end

  it "updates the call's sid" do
    @call.sid.should == @sid
  end

  it 'returns an empty TwiML document (whisper tone)' do
    response.body.should be_whisper_tone
  end
end
