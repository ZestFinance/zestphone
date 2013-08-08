module Telephony
  module Jobs
    class AgentOffline
      attr_accessor :id, :timestamp

      def initialize id, timestamp
        @id = id
        @timestamp = timestamp
      end

      def update_status
        Agent.find_with_lock(id) do |agent|
          agent.update_status_by_event Agent::OFFLINE, timestamp
        end
      end

      def perform
        update_status
      end

      def failure
        Rails.logger.error "#{self.class}: #{self.as_json}"
        ActiveSupport::Notifications
          .instrument("telephony.agent_offline_failure", self)
      end
    end
  end
end
