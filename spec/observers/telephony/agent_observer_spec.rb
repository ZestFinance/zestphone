require 'spec_helper'

module Telephony
  describe AgentObserver do
    before do
      ActiveRecord::Base.observers.enable 'Telephony::AgentObserver'
      AgentObserver.instance
    end

    describe "#after_save" do
      before do
        @agent = create :offline_agent
        @agent.should_receive(:publish_status_change)
      end

      it "asks the agent to publish its status change" do
        @agent.available!
      end
    end
  end
end
