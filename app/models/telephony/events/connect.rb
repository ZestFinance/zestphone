module Telephony
  module Events
    class Connect < Base
      def publishable?
        !conversation_state.in?(['one_step_transferring', 'two_step_transferring', 'two_step_transferring_hold']) &&
          call &&
          call.agent?
      end

      def agent_messages
        [
          {
            agent: call.agent,
            data: {
              owner: agent1 == call.agent
            }
          }
        ]
      end
    end
  end
end
