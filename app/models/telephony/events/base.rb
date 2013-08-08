module Telephony
  module Events
    class Base < ::Telephony::Base
      self.table_name = 'telephony_conversation_events'

      attr_accessible :conversation_id,
        :conversation_state,
        :call_id,
        :call_state,
        :message_data

      serialize :message_data, Array

      belongs_to :conversation, include: { calls: :agent }

      def self.log(args)
        klass = "Telephony::Events::#{args[:name].to_s.camelcase}".constantize
        event = klass.new args[:data]
        event.message_data = event.publishable? ? event.agent_messages : []
        event.save
      end

      def self.find_last_for_agent(agent)
        return new_default_event unless agent.on_a_call?

        call = agent.calls.last
        return new_default_event unless call

        events = call.conversation.events.order(:id).reverse_order

        events.detect do |event|
          event.for_agent?(agent)
        end || new_default_event
      end

      def self.new_default_event
        InitializeWidget.new
      end

      def call
        conversation.calls.detect { |call| call.id == call_id }
      end

      def publish
        each_message do |agent, data|
          PusherEventPublisher.publish event_publisher_data(agent, data)
        end
      end

      def republish_only_for(current_agent)
        each_message do |agent, data|
          if agent == current_agent
            PusherEventPublisher.publish event_publisher_data(agent, data)
          end
        end
      end

      def publishable?
        false
      end

      def agent_messages
        []
      end

      def default_data
        {
          event_id: id,
          conversation_id: conversation.id,
          conversation_state: conversation.state,
          call_id: call_id,
          number: conversation.customer.number,
          loan_id: conversation.loan_id,
          owner: true
        }
      end

      def for_agent?(agent)
        # TODO Remove a week after the launch of the message_data field
        agent.in?((message_data || []).map { |message| message[:agent] })
      end

      def agent1
        @agent1 ||= conversation.first_active_agent
      end

      def agent2
        @agent2 ||= conversation.calls.last.agent
      end

      def active_agent2
        return @active_agent2 if @active_agent2
        leg = conversation.active_agent_legs.last
        agent = leg.agent if leg
        @active_agent2 = agent if agent != agent1
      end

      private

      def each_message
        # TODO Remove a week after the launch of the message_data field
        messages = message_data || []
        messages.each do |message|
          agent, data = message.values_at :agent, :data
          yield agent, data if agent.present?
        end
      end

      def event_publisher_data(agent, data)
        {
          channel: "csrs-#{agent.csr_id}",
          name: self.class.name.demodulize,
            data: default_data.merge(data || {})
        }
      end
    end
  end
end
