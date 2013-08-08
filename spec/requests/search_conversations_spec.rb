require 'spec_helper'

describe 'Search for conversations' do
  before do
    agent = create :agent
    conversation = create :conversation
    create :conversation, created_at: (conversation.created_at - 1.second)
    create :conversation_connect_event, conversation: conversation

    call = create :call_with_recording,
      conversation: conversation,
      agent: agent
    create :customer_leg,
      conversation: conversation,
      number: '555-555-1111'

    create :voicemail,
      call: call

    attributes = {}

    xhr :get,
      '/zestphone/conversations/search',
      attributes

    json = JSON.parse(response.body)
    conversations = json['conversations']
    @total_count = json['total_count']

    @conversation = conversations.first

    @call = @conversation['calls'].first
    @voicemail = @call['voicemail']
    @agent = @call['agent']
    @event = @conversation['events'].first
    @recording = @call['recordings'].first
  end

  it 'returns conversations as JSON' do
    @conversation.should include('id')
    @conversation.should include('created_at')
    @conversation.should include('loan_id')
    @conversation.should include('state')
    @conversation.should include('number')
    @conversation.should include('customer_number')
    @conversation.should include('conversation_type')
    @conversation.should include('calls')
    @conversation.should include('events')
  end

  it 'returns calls as JSON' do
    @call.should include('id')
    @call.should include('number')
    @call.should include('sid')
    @call.should include('state')
    @call.should include('created_at')
    @call.should include('agent')
    @call.should include('voicemail')
    @call.should include('recordings')
  end

  it 'returns events as JSON' do
    @event.should include('id')
    @event.should include('type')
    @event.should include('conversation_id')
    @event.should include('conversation_state')
    @event.should include('call_id')
    @event.should include('call_state')
    @event.should include('agent')
    @event.should include('elapsed_seconds')
    @event.should include('created_at')
  end

  it 'returns an agent as JSON' do
    @agent.should include('id')
    @agent.should include('csr_id')
    @agent.should include('name')
    @agent.should include('status')
    @agent.should include('phone_type')
    @agent.should include('phone_number')
    @agent.should include('sip_number')
  end

  it 'returns a voicemail as JSON' do
    @voicemail.should include('id')
    @voicemail.should include('duration')
    @voicemail.should include('url')
  end

  it 'returns recordings as JSON' do
    @recording.should include('id')
    @recording.should include('duration')
    @recording.should include('url')
  end

  it 'returns a total_count' do
    count = Telephony::Conversation.count

    @total_count.should == count
  end
end
