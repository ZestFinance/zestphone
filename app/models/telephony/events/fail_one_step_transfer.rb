module Telephony
  module Events
    class FailOneStepTransfer < Transfer
      def agent1
        @agent1 ||= conversation.first_inactive_agent
      end
    end
  end
end
