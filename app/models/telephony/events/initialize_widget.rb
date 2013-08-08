module Telephony
  module Events
    class InitializeWidget
      def id
        1
      end

      def republish_only_for(current_agent)
        PusherEventPublisher.publish channel: "csrs-#{current_agent.csr_id}",
                                name: self.class.name.demodulize,
                                data: {}
      end
    end
  end
end
