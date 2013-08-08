require "spec_helper"

module Telephony
  describe Providers::Twilio::CallsController do
    before { @routes = Engine.routes }

    describe "#complete_hold" do
      context "given an 'initiating_hold' conversation" do
        before do
          @conversation = create :initiating_hold_conversation
          @cust_leg     = create :in_progress_call, conversation: @conversation
          @agent_leg    = create :active_agent_leg, state: 'in_conference', conversation: @conversation

          post :complete_hold, id: @cust_leg.id

          @cust_leg.reload
        end

        it "updates the call's state to 'in_progress_hold'" do
          @cust_leg.should be_in_progress_hold
        end

        it 'returns TwiML for joining the hold queue' do
          @cust_leg.should complete_hold
        end

        it "sets conversation's state to 'in_progress_hold'" do
          @conversation.reload.should be_in_progress_hold
        end
      end
    end
  end
end
