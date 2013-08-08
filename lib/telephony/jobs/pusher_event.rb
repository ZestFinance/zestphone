module Telephony
  module Jobs
    class PusherEvent
      attr_reader :event

      def initialize(event)
        @event = event
      end

      def perform
        Telephony::PusherEventPublisher.push(@event)
      end

      def failure
        Rails.logger.error "#{self.class}: #{self.as_json}"
        ActiveSupport::Notifications
          .instrument("telephony.agent_offline_failure", self)
      end
    end
  end
end
