require 'spec_helper'

describe Telephony::Jobs::AgentOffline do
  describe '#perform' do
    let(:old_timestamp) { 50 }
    let(:new_timestamp) { 100 }

    before do
      @agent = create :available_agent,
        timestamp_of_last_presence_event: old_timestamp
      @job = Telephony::Jobs::AgentOffline.new @agent.id, new_timestamp
      @job.perform
    end

    context "when an agent didn't receive any new status change events" do
      it "sets an agent to offline" do
        @agent.reload.should be_offline
      end

      it "updates a timestamp" do
        @agent.reload.timestamp_of_last_presence_event.should == new_timestamp
      end
    end

    context "when an agent received a newer status change event" do
      let(:old_timestamp) { 150 }

      it "doesn't change the status" do
        @agent.reload.should be_available
      end

      it "doesn't update a timestamp" do
        @agent.reload.timestamp_of_last_presence_event.should == old_timestamp
      end
    end
  end
end
