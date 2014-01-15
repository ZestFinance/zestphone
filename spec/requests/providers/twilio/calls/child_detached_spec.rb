require 'spec_helper'

describe 'Given a two step transfer' do
  before do
    @conversation = create :conversation, state: :two_step_transferring
    @call = create :active_agent_leg, conversation: @conversation
    participant = create :call, conversation: @conversation

    post "/zestphone/providers/twilio/calls/#{@call.id}/child_detached",
      DialCallSid: participant.sid,
      DialCallStatus: 'completed'
  end

  it 'returns TwiML for redirecting the caller into the same conference' do
    @call.should join_conference
  end
end

describe 'When the child call is completed' do
  context 'and there is a DialCallDuration (which is supposed to mean that the call is hung up)' do
    before do
      agent = create :agent
      @call = create :call, agent: agent
      @conversation = @call.conversation
      @child_call = create :call, conversation: @conversation
      @recording_url = 'recording_url'
      @recording_duration = 0

      post "/zestphone/providers/twilio/calls/#{@call.id}/child_detached",
        DialCallSid: @child_call.sid,
        DialCallDuration: '0',
        DialCallStatus: 'completed',
        RecordingUrl: @recording_url,
        RecordingDuration: @recording_duration
    end

    it 'returns TwiML to hangup the caller' do
      response.body.should be_hangup
    end

    it 'terminates the child call' do
      @child_call.reload
      @child_call.should be_terminated
    end
  end

  context "and the conversation is initiating_hold" do
    context "and the agent's call is the parent" do
      before do
        agent         = create :agent
        @agent_leg    = create :holding_agent_call, agent: agent
        @conversation = @agent_leg.conversation
        @cust_leg     = create :call, conversation: @conversation

        post "/zestphone/providers/twilio/calls/#{@agent_leg.id}/child_detached",
          DialCallSid: @cust_leg.sid,
          DialCallStatus: 'completed'
      end

      it "sets call's state to 'in_conference'" do
        @agent_leg.reload.should be_in_conference
      end

      it "redirects the call to a conference" do
        @agent_leg.should join_conference
      end
    end

    context "and the customer's call is the parent" do
      before do
        @cust_leg     = create :holding_cust_call
        @conversation = @cust_leg.conversation
        agent         = create :agent
        @agent_leg    = create :holding_agent_call, agent: agent, conversation: @conversation

        post "/zestphone/providers/twilio/calls/#{@cust_leg.id}/child_detached",
          DialCallSid: @agent_leg.sid,
          DialCallStatus: 'completed'
      end

      it "sets call's state to 'in_progress_hold'" do
        @cust_leg.reload.should be_in_progress_hold
      end

      it "redirects the call to the hold queue" do
        @cust_leg.should complete_hold
      end
    end
  end

  context 'and there is not a DialCallDuration' do
    before do
      agent = create :agent
      @call = create :call, agent: agent
      @conversation = @call.conversation
      @child_call = create :call, conversation: @conversation
      @recording_url = 'recording_url'
      @recording_duration = 0

      post "/zestphone/providers/twilio/calls/#{@call.id}/child_detached",
        DialCallSid: @child_call.sid,
        DialCallStatus: 'completed',
        RecordingUrl: @recording_url,
        RecordingDuration: @recording_duration
    end

    it 'does not terminate the child call' do
      @child_call.reload
      @child_call.should_not be_terminated
    end
  end
end

describe 'When the child call is unanswered' do
  before do
    call = create :active_agent_leg
    @connecting_call = create :connecting_call, conversation: call.conversation, sid: nil
    @sid = '123'

    post "/zestphone/providers/twilio/calls/#{call.id}/child_detached",
      DialCallStatus: 'no-answer',
      DialCallSid: @sid
  end

  it 'sets the sid of the child call' do
    @connecting_call.reload.sid.should == @sid
  end

  it 'sets the participant call state to no_answer' do
    @connecting_call.reload
    @connecting_call.should be_terminated
  end

  it 'returns an empty TwiML response (whisper tone)' do
    response.body.should be_hangup
  end
end

describe 'When the child call fails' do
  before do
    call = create :active_agent_leg
    @connecting_call = create :connecting_call, conversation: call.conversation, sid: nil
    @sid = '123'

    post "/zestphone/providers/twilio/calls/#{call.id}/child_detached",
      DialCallStatus: 'failed',
      DialCallSid: @sid
  end

  it 'sets the sid of the child call' do
    @connecting_call.reload.sid.should == @sid
  end

  it 'sets the participant call state to call_failed' do
    @connecting_call.reload
    @connecting_call.should be_terminated
  end

  it 'returns an empty TwiML response (whisper tone)' do
    response.body.should be_hangup
  end
end

describe 'When the child call is busy' do
  before do
    call = create :active_agent_leg
    @connecting_call = create :connecting_call, conversation: call.conversation, sid: nil
    @sid = '123'

    post "/zestphone/providers/twilio/calls/#{call.id}/child_detached",
      DialCallStatus: 'busy',
      DialCallSid: @sid
  end

  it 'sets the sid of the child call' do
    @connecting_call.reload.sid.should == @sid
  end

  it 'sets the participant call state to busy' do
    @connecting_call.reload
    @connecting_call.should be_terminated
  end

  it 'returns an empty TwiML response (whisper tone)' do
    response.body.should be_hangup
  end
end

describe 'Given a one step transfer' do
  context 'for a completed call' do
    before do
      agent = create :agent
      @call = create :one_step_transfer_call, agent: agent
      participant1 = create :in_progress_call, conversation: @call.conversation
      create :connecting_call, conversation: @call.conversation

      post "/zestphone/providers/twilio/calls/#{@call.id}/child_detached",
        DialCallSid: participant1.sid,
        DialCallStatus: 'completed'
    end

    it 'returns an empty TwiML response (whisper tone)' do
      response.body.should be_hangup
    end
  end

  context 'for an unanswered call' do
    before do
      @conversation = create :one_step_transferring_conversation
      @agent = @conversation.active_agent_leg.agent

      post "/zestphone/providers/twilio/calls/#{@conversation.customer.id}/child_detached",
        DialCallStatus: 'no-answer'
    end

    it 'renders the voicemails/new twiml' do
      xml = Nokogiri::XML response.body
      say = xml.at '/Response/Say'
      say.text.should =~ /at extension #{@agent.phone_ext}/i
      say.text.should =~ /record your message/i
      record = xml.at '/Response/Record'
      record.attributes['action'].value.should == "/zestphone/providers/twilio/calls/#{@conversation.customer.id}/voicemail?csr_id=#{@agent.csr_id}"

    end
  end
end

describe 'Given a RONAed call' do
  before do
    conversation = create :rona_conversation
    @customer_leg = conversation.customer
    agent_leg = conversation.active_agent_leg

    post "/zestphone/providers/twilio/calls/#{@customer_leg.id}/child_detached",
      DialCallSid: agent_leg.sid,
      DialCallStatus: 'no-answer'
  end

  it 'enqueues the call into the inbound queue' do
    xml = Nokogiri::XML response.body
    enqueue = xml.at '/Response/Enqueue'
    enqueue.text.should == 'inbound'
    enqueue.attributes['waitUrl'].value
      .should =~ %r{/zestphone/providers/twilio/inbound_calls/wait_music$}
    enqueue.attributes['waitUrlMethod'].value.should == 'GET'
    enqueue.attributes['action'].value
      .should == "/zestphone/providers/twilio/calls/#{@customer_leg.id}/leave_queue"
  end
end
