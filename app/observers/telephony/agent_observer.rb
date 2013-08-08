module Telephony
  class AgentObserver < ActiveRecord::Observer

    def after_save agent
      agent.publish_status_change unless agent.offline?
    end
  end
end
