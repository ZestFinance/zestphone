module Telephony
  module Events
    class LeaveVoicemail < Base
      def publishable?
        true
      end

      def agent_messages
        [
          {
            agent: agent1,
            data: {
              agent_name: agent2.name,
              agent_ext: agent2.phone_ext,
              agent_type: agent2.csr_type
            }
          }
        ]
      end
    end
  end
end
