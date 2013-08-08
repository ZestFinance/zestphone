module Telephony
  module Events
    class Transfer < Base
      self.abstract_class = true

      def publishable?
        true
      end

      def agent_messages
        [
          {
            agent: agent1,
            data: {
              transferrer: true,
              agent_name: agent2.name,
              agent_ext: agent2.phone_ext,
              agent_type: agent2.csr_type
            }
          },
          {
            agent: agent2,
            data: {
              transferrer: false,
              agent_name: agent1.name,
              agent_ext: agent1.phone_ext,
              agent_type: agent1.csr_type,
              owner: false
            }
          }
        ]
      end
    end
  end
end
