module Telephony
  class InboundConversationQueue
    def self.play_message(args)
      Conversation.transaction do
        conversation = Conversation.create_inbound! number: args[:To], caller_id: args[:To]
        conversation.play_message!
        customer_leg = conversation.calls.create! number: args[:From], sid: args[:CallSid]
        customer_leg.connect!
        customer_leg.answer!
        conversation
      end
    end

    def self.play_closed_greeting(args)
      Conversation.transaction do
        conversation = Conversation.create_inbound! number: args[:To], caller_id: args[:To]
        conversation.play_closed_greeting!
        customer_leg = conversation.calls.create! number: args[:From], sid: args[:CallSid]
        customer_leg.terminate!
        conversation
      end
    end

    def self.reject(args)
      Conversation.transaction do
        conversation = Conversation.create_inbound! number: args[:To], caller_id: args[:To]
        customer_leg = conversation.calls.create! number: args[:From], sid: args[:CallSid]
        customer_leg.reject!
        conversation
      end
    end

    def self.dequeue(csr_id)
      with_agent_on_a_call(csr_id) do |agent|
        begin
          conversation = oldest_queued_conversation

          if conversation
            agent_call = conversation.calls.create! number: agent.phone_number, agent: agent
            agent_call.connect!

            conversation.customer.redirect_to_inbound_connect csr_id

            pop_url = Telephony.pop_url_finder &&
                      Telephony.pop_url_finder.find(conversation.customer.sanitized_number)

            {
              id: conversation.id,
              customer_number: conversation.customer.number,
              pop_url: pop_url
            }
          else
            raise Telephony::Error::QueueEmpty.new
          end
        rescue Telephony::Error::NotInProgress
          agent_call.destroy
          conversation.customer.terminate!
          retry
        end
      end
    end

    def self.oldest_queued_conversation
      Conversation.transaction do
        conversation = Conversation
          .where(state: 'enqueued')
          .order(:created_at)
          .lock(true)
          .first

        conversation.connect! if conversation
        conversation
      end
    end

    private

    def self.with_agent_on_a_call csr_id
      old_status = ''
      agent = nil

      Agent.transaction do
        agent = Agent.find_by_csr_id(csr_id, lock: true)

        if agent.on_a_call?
          raise Telephony::Error::AgentOnACall.new
        else
          old_status = agent.status
          agent.on_a_call
        end

        begin
          yield agent
        rescue => error
          agent.fire_events old_status
          raise error
        end
      end
    end
  end
end
