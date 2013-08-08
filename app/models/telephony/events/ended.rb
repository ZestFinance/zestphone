module Telephony
  module Events
    class Ended < Base
      self.abstract_class = true

      def publishable?
        call && call.agent?
      end

      def agent_messages
        [
          {
            agent: call.agent
          }
        ]
      end
    end
  end
end
