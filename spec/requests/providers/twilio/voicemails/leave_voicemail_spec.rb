require 'spec_helper'

describe "Leaving a voicemail for a callee that didn't answer" do
  before do
    Telephony::Providers::Twilio::VoicemailsController.any_instance.stub(:verify_twilio_request).and_return(true)
    @conversation = create :one_step_transferring_conversation
    @call = @conversation.calls.first
    agent_call = @conversation.calls.last
    @agent = agent_call.agent

    post "/zestphone/providers/twilio/calls/#{@call.id}/child_detached",
      DialCallStatus: 'no-answer',
      DialCallSid: agent_call.sid
  end

  it 'returns TwiML for recording a voicemail' do
    xml = Nokogiri::XML response.body
    say = xml.at '/Response/Say'
    say.text.should =~ /at extension #{@agent.phone_ext}/i
    say.text.should =~ /record your message/i
    record = xml.at '/Response/Record'
    record.attributes['action'].value.should == "/zestphone/providers/twilio/calls/#{@call.id}/voicemail?csr_id=#{@agent.csr_id}"
  end
end

describe 'Leaving a voicemail for a completed call' do
  before do
    Telephony::Providers::Twilio::VoicemailsController.any_instance.stub(:verify_twilio_request).and_return(true)
    agent = create :agent
    original_call = create :terminated_call, agent: agent
    @conversation = original_call.conversation
    call = create :in_progress_call, conversation: original_call.conversation
    @child_call = create :in_progress_call, conversation: original_call.conversation

    post "/zestphone/providers/twilio/calls/#{call.id}/child_detached",
      DialCallStatus: 'completed',
      DialCallSid: @child_call.sid,
      DialCallDuration: 1
  end

  it 'returns a TwiML hangup' do
    response.body.should be_hangup
  end

  it 'sets the agent call to terminated' do
    @child_call.reload.should be_terminated
  end
end

describe 'Saving a voicemail' do
  before do
    Telephony::Providers::Twilio::VoicemailsController.any_instance.stub(:verify_twilio_request).and_return(true)
    agent = create :agent
    @call = create :call, agent: agent
    @csr_id = 1
    @recording_url = 'recording_url'
    @recording_duration = 1

    post "/zestphone/providers/twilio/calls/#{@call.id}/voicemail",
      { csr_id: @csr_id,
        RecordingUrl: @recording_url,
        RecordingDuration: @recording_duration}
  end

  it 'creates a voicemail for the call' do
    @call.reload
    voicemail = @call.voicemail
    voicemail.should be
    voicemail.csr_id.should == @csr_id
    voicemail.url.should == @recording_url
    voicemail.duration.should == @recording_duration
  end

  it 'returns a success response' do
    response.code.should == '200'
    response.body.should be_whisper_tone
  end
end
