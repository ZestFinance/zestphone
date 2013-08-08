require 'state_machine'

module Telephony
  module AgentStateMachine
    extend ActiveSupport::Concern

    included do
      state_machine :status, :initial => :offline do
        event :available do
          transition any => :available
        end

        event :came_online do
          transition :offline => :available
        end

        event :offline do
          transition all - [:offline] => :offline
        end

        event :on_a_call do
          transition :available => :on_a_call
          transition :not_available => :on_a_call
        end

        event :not_available do
          transition [:offline, :on_a_call, :available] => :not_available
        end

        event :toggle_available do
          transition :available => :not_available
          transition :not_available => :available
        end

        after_transition do |agent, transition|
          unless transition.loopback?
            ActiveSupport::Notifications
              .instrument("telephony.agent_status_change",
              {
                agent_id: agent.id,
                csr_id: agent.csr_id,
                status: transition.to,
                timestamp: Time.now.to_i
              })
          end
        end
      end
    end
  end
end
