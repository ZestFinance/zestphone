module Telephony
  module Events
    class CompleteResume < Base
      def publishable?
        true
      end

      def agent_messages
        msgs = [
                 {
                   agent: agent1
                 }
               ]

        if active_agent2
          msgs << {
            agent: active_agent2,
            data: {
              owner: false
            }
          }
        end

        msgs
      end
    end
  end
end
