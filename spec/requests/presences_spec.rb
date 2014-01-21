require 'spec_helper'

describe 'Reloading the widget during a call', :vcr do
  include PusherSignatureHelper

  describe '#create' do
    context "during a call" do
      context "after a failed transfer" do
        before do
          @conversation1 = create(:connecting_conversation).tap do |conversation|
            create :active_agent_leg, conversation: conversation
            create :connecting_call, conversation: conversation
          end

          @conversation2 = create(:in_progress_conversation).tap do |conversation|
            create :active_agent_leg, conversation: conversation
            create :customer_leg, conversation: conversation
          end

          @conversation1.calls.last.answer!
          @conversation1.start!

          @agent = @conversation1.calls.first.agent
          @agent.available!
          @agent.on_a_call!

          @payload = {
            "presence" => {
              "time_ms" => 9223372036854775705,
              "events" => [
                           { "name" => "member_added",
                             "channel" => "presence-#{@agent.csr_id}",
                             "user_id" => "#{@agent.id}" }
                          ]
            }
          }
        end

        it "pushes the event for the active call" do
          Telephony::Events::Base.last.should be_a_kind_of(Telephony::Events::Start)

          @conversation2.transfer!(@conversation1.calls.first.agent.csr_id, true)

          Telephony::Events::Start.any_instance.should_receive(:republish_only_for)
          
          post '/zestphone/signals/agents/presences', @payload.to_query, get_pusher_params(@payload)
        end
      end
    end
  end
end
