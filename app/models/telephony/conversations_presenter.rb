module Telephony
  class ConversationsPresenter
    attr_accessor :conversations

    def initialize(conversations)
      self.conversations = conversations
    end

    def as_json(args = nil)
      conversations.map { |convo| conversation_presenter(convo) }
    end

  private

    def conversation_presenter(conversation)
      {
        id: conversation.id,
        created_at: conversation.created_at,
        loan_id: conversation.loan_id,
        state: conversation.state,
        number: conversation.number,
        customer_number: conversation.customer ? conversation.customer.number : nil,
        conversation_type: conversation.conversation_type,
        calls: conversation.calls.map { |call| call_presenter(call) },
        events: conversation.events.map { |event| event_presenter(event, conversation) }
      }
    end

    def call_presenter(call)
      {
        id: call.id,
        number: call.number,
        sid: call.sid,
        state: call.state,
        created_at: call.created_at,
        agent: call.agent ? agent_presenter(call.agent) : nil,
        voicemail: call.voicemail ? recording_presenter(call.voicemail): nil,
        recordings: call.recordings.map { |recording| recording_presenter(recording) }
      }
    end

    def event_presenter(event, conversation)
      {
        id: event.id,
        type: event.type,
        conversation_id: event.conversation_id,
        conversation_state: event.conversation_state,
        call_id: event.call_id,
        call_state: event.call_state,
        call_number: (event.call ? event.call.number(true) : nil),
        agent: mapped_agent(event, conversation),
        elapsed_seconds: event.created_at.to_i - conversation.events.first.created_at.to_i,
        created_at: event.created_at
      }
    end

    def agent_presenter(agent)
      {
        id: agent.id,
        csr_id: agent.csr_id,
        csr_type: agent.csr_type,
        name: agent.name,
        status: agent.status,
        phone_type: agent.phone_type,
        phone_number: agent.phone_number,
        sip_number: agent.sip_number
      }
    end

    def recording_presenter(recording)
      {
        id: recording.id,
        duration: recording.duration,
        url: recording.url
      }
    end

    def mapped_agent(event, conversation)
      call = conversation.calls.find { |c| c.id == event.call_id }
      call && call.agent ? agent_presenter(call.agent) : nil
    end
  end
end
