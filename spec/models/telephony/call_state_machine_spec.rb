require 'spec_helper'

module Telephony
  describe CallStateMachine do
    describe '#state' do
      before do
        @call = create :call
      end

      it 'defaults to "not_initiated"' do
        @call.state.should == 'not_initiated'
      end
    end

    describe '#connect!' do
      before do
        @call = create :call
        @call.connect!
      end

      it 'transitions to "connecting"' do
        @call.state.should == 'connecting'
      end

      it 'logs a connect event' do
        event = Events::Connect.last
        event.should be
      end
    end

    describe '#reject!' do
      before do
        @call = create :call
        @call.reject!
      end

      it 'transitions to "terminated"' do
        @call.should be_terminated
      end

      it 'logs a reject event' do
        event = Events::Reject.where(call_id: @call.id).last
        event.should be
      end
    end

    describe '#no_answer!' do
      before do
        @call = create :connecting_call
        @call.no_answer!
      end

      it 'transitions to "terminated"' do
        @call.state.should == 'terminated'
      end

      it 'logs a no answer event' do
        event = Events::NoAnswer.last
        event.should be
      end
    end

    describe '#busy!' do
      before do
        @call = create :connecting_call
        @call.busy!
      end

      it 'transitions to "terminated"' do
        @call.state.should == 'terminated'
      end

      it 'logs a busy event' do
        event = Events::Busy.last
        event.should be
      end
    end

    describe '#call_fail!' do
      before do
        @call = create :connecting_call
        @call.call_fail!
      end

      it 'transitions to "terminated"' do
        @call.state.should == 'terminated'
      end

      it 'logs a call fail event' do
        event = Events::CallFail.last
        event.should be
      end
    end

    describe '#answer!' do
      context 'given a connecting call' do
        before do
          @call = create :connecting_call
          @call.answer!
        end

        it 'transitions to "in_progress"' do
          @call.state.should == 'in_progress'
        end

        it 'sets a connected timestamp' do
          @call.connected_at.should be
        end

        it 'logs a answer event' do
          event = Events::Answer.last
          event.should be
        end
      end

      context 'given a terminated call' do
        before do
          @call = create :terminated_call, terminated_at: nil
          @call.answer!
        end

        it 'transitions to "terminated"' do
          @call.state.should == 'terminated'
        end

        it 'logs a terminate event' do
          event = Events::Terminate.last
          event.should be
        end
      end
    end

    describe '#conference!' do
      context 'given a connecting call' do
        before do
          @call = create :connecting_call

          @conversation = @call.conversation
          @call.stub(:conversation).with(true).and_return(@conversation)
          @call.stub(:conversation).and_return(@conversation)

          @call
            .conversation
            .should_receive(:check_for_successful_transfer)
          @call
            .conversation
            .should_receive(:check_for_successful_resume)
          @call
            .conversation
            .should_receive(:check_for_successful_hold)
          @call.conference!
        end

        it 'transitions to "in_conference"' do
          @call.state.should == 'in_conference'
        end

        it 'logs a conference event' do
          event = Events::Conference.last
          event.should be
        end
      end

      context 'given an in progress call' do
        before do
          @call = create :in_progress_call
          @call.conference!
        end

        it 'transitions to "in_conference"' do
          @call.state.should == 'in_conference'
        end

        it 'logs a conference event' do
          event = Events::Conference.last
          event.should be
        end
      end

      context 'given an in progress hold call' do
        before do
          @call = create :call, state: 'in_progress_hold'
          @call.conference!
        end

        it 'transitions to "in_conference"' do
          @call.state.should == 'in_conference'
        end

        it 'logs a conference event' do
          event = Events::Conference.last
          event.should be
        end
      end

      context 'given a terminated call' do
        before do
          @call = create :terminated_call, terminated_at: nil
          @call.conference!
        end

        it 'transitions to "terminated"' do
          @call.state.should == 'terminated'
        end

        it 'logs a terminate event' do
          event = Events::Terminate.last
          event.should be
        end
      end
    end

    describe '#dial_agent!' do
      context 'given an in_conference call' do
        before do
          @call = create :in_conference_call
          @call.dial_agent!
        end

        it 'transitions to "in_progress"' do
          @call.state.should == 'in_progress'
        end

        it 'logs a RemoveFromConference event' do
          event = Events::DialAgent.last
          event.should be
        end
      end

      context 'given an in_progress call' do
        before do
          @call = create :in_progress_call
          @call.dial_agent!
        end

        it 'transitions to "in_progress"' do
          @call.state.should == 'in_progress'
        end
      end

      context 'given an in_progress_hold call' do
        before do
          @call = create :call, state: 'in_progress_hold'
          @call.dial_agent!
        end

        it 'transitions to "in_progress"' do
          @call.state.should == 'in_progress'
        end
      end
    end

    describe "#complete_hold!" do
      context "given an 'in_progress' call" do
        before do
          @call = create :in_progress_call
          @call.complete_hold!
        end

        it "transitions to 'in_progress_hold'" do
          @call.should be_in_progress_hold
        end
      end

      context 'given a terminated call' do
        before do
          @call = create :terminated_call, terminated_at: nil
          @call.complete_hold!
        end

        it 'transitions to "terminated"' do
          @call.state.should == 'terminated'
        end

        it 'logs a terminate event' do
          event = Events::Terminate.last
          event.should be
        end
      end
    end

    describe '#terminate!' do
      context "by default" do
        before do
          @call = create :connecting_call
          @conversation = @call.conversation

          @call.stub(:conversation).with(true).and_return(@conversation)
          @call.stub(:conversation).and_return(@conversation)

          @call
            .conversation
            .should_receive(:check_for_terminate)
          @call.terminate!
        end

        it 'transitions to "terminated"' do
          @call.state.should == 'terminated'
        end

        it 'sets a terminated timestamp' do
          @call.terminated_at.should be
        end

        it 'logs a terminate event' do
          event = Events::Terminate.last
          event.should be
        end
      end

      context 'given a call in which the second leg fails' do
        before do
          @call = create :connecting_call
          create :failed_call,
            conversation: @call.conversation
        end

        it 'does not try to hangup on the second leg' do
          provider = stub 'provider'
          provider.should_not_receive :hangup
          Telephony
            .stub(:provider)
            .and_return(provider)

          @call.terminate!
        end
      end

      context 'call is already terminated' do
        before do
          @call = create :terminated_call, terminated_at: nil
        end

        it "doesn't raise an error" do
          expect { @call.terminate! }.to_not raise_error
        end

        it "doesn't update terminated_at" do
          expect { @call.terminate! }.to_not change(@call, :terminated_at)
        end
      end
    end

    describe 'transitioning to terminated' do
      context 'given a conversation in a one step transfer' do
        before do
          @conversation = create :initiating_one_step_transferring_conversation
        end

        context 'and with one active call' do
          before do
            @conversation.active_agent_leg.terminate!
          end

          it 'fails the one step transfer' do
            @conversation.reload
            @conversation.should be_leaving_voicemail
          end
        end

        context 'and with more than one active call' do
          before do
            call = create :call,
              conversation: @conversation
            @conversation.reload
            call.terminate!
          end

          it 'does not fail the one step transfer' do
            @conversation.reload
            @conversation.should_not be_leaving_voicemail
          end
        end
      end

      context 'given a conversation with no active calls' do
        before do
          @conversation = create :conversation
          @call = create :in_progress_call, conversation: @conversation
        end

        context 'that is not terminated' do
          before do
            @call.terminate!
            @conversation.reload
          end

          it 'terminates the conversation' do
            @conversation.should be_terminated
          end
        end

        context 'that is terminated' do
          before do
            @conversation.update_attribute :state, 'terminated'
          end

          it 'does not terminate the conversation' do
            expect { @call.terminate! }.to_not raise_error
          end
        end
      end

      context 'given an inbound conversation' do
        before do
          @conversation = create :inbound_conversation
        end

        context 'that an agent failed to answer' do
          before do
            @conversation.connect!
            agent_leg = @conversation.active_agent_leg
            agent_leg.connect!

            agent_leg.no_answer!
          end

          it 'RONAs the conversation' do
            Telephony::Events::Rona.where(conversation_id: @conversation.id).should be_exist
          end
        end

        context 'that a borrower hung up on' do
          before do
            @conversation.connect!

            @conversation.customer.terminate!
          end

          it 'does NOT RONA the conversation' do
            Telephony::Events::Rona.where(conversation_id: @conversation.id).should_not be_exist
          end
        end
      end

      context 'given a RONAed conversation' do
        before do
          @conversation = create :inbound_conversation
          @conversation.customer.connect!
          @conversation.customer.answer!
          @conversation.connect!

          agent1_leg = @conversation.active_agent_leg
          agent1_leg.connect!
          agent1_leg.no_answer!
        end

        context 'that is re-RONAed' do
          before do
            @conversation.reload.connect!
            agent2_leg = create :call,
              agent: create(:agent),
              conversation: @conversation
            agent2_leg.connect!
            agent2_leg.no_answer!
          end

          it 'does not hang up on the customer' do
            @conversation.reload
            @conversation.customer.should be_in_progress
          end

          it 're-RONAs the conversation' do
            @conversation.reload
            @conversation.should be_enqueued
          end

          it 'creates another RONA event' do
            @conversation.reload
            Telephony::Events::Rona.where(conversation_id: @conversation.id).count.should == 2
          end
        end
      end

      context 'given an in progress two step transfer conversation' do
        before do
          @conversation = create :in_progress_two_step_transfer_conversation
          @agent1_leg   = create :active_agent_leg, conversation: @conversation
          @customer_leg = create :call, conversation: @conversation
          @agent2_leg   = create :active_agent_leg, conversation: @conversation
        end

        context 'with the customer on the call' do
          context 'an agent hangs up' do
            before do
              @agent2_leg.terminate!
            end

            it 'changes the conversation to in progress' do
              @conversation.reload
              @conversation.should be_in_progress
            end
          end

          context 'a customer hangs up' do
            before do
              @customer_leg.terminate!
            end

            it 'changes the conversation to agents only' do
              @conversation.reload
              @conversation.should be_agents_only
            end
          end
        end

        context 'with the customer on hold' do
          before do
            @conversation.initiate_hold
            @conversation.complete_hold
          end

          context 'an agent hangs up' do
            before do
              @agent2_leg.terminate!
            end

            it 'changes the conversation to in progress' do
              @conversation.reload
              @conversation.should be_in_progress_hold
            end
          end

          context 'a customer hangs up' do
            before do
              @customer_leg.terminate!
            end

            it 'changes the conversation to agents only' do
              @conversation.reload
              @conversation.should be_agents_only
            end
          end
        end
      end
    end
  end
end
