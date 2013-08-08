module Telephony
  module Events
    class CallAnswered < Base
      self.abstract_class = true

      def publishable?
        call && call.agent?
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
