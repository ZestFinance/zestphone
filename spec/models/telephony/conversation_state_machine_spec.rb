require 'spec_helper'

module Telephony
  describe ConversationStateMachine do
    describe '#state' do
      before do
        @conversation = create :conversation
      end

      it 'defaults to "initiated"' do
        @conversation.state.should == 'initiated'
      end
    end

    describe '#connect!' do
      before do
        @conversation = create :conversation
        @conversation.connect!
      end

      it 'transitions to "connecting"' do
        @conversation.state.should == 'connecting'
      end

      it 'logs a connect event' do
        event = Events::Connect.last
        event.should be
        event.conversation_id.should == @conversation.id
        event.conversation_state.should == @conversation.state
      end
    end

    describe '#start!' do
      context 'from connecting' do
        before do
          @conversation = create :connecting_conversation
          @conversation.start!
        end

        it 'transitions to "in_progress"' do
          @conversation.should be_in_progress
        end

        it 'logs a start event' do
          event = Events::Start.last
          event.should be
        end
      end
    end

    describe '#initiate_one_step_transfer!' do
      context "from in_progress" do
        before do
          @conversation = create :in_progress_conversation_with_calls
          @conversation.initiate_one_step_transfer!
        end

        it 'transitions to "one_step_transferring"' do
          @conversation.state.should == 'one_step_transferring'
        end

        it 'logs a one step transfer initiated event' do
          event = Events::InitiateOneStepTransfer.last
          event.should be
        end
      end

      context "from in_progress_hold" do
        it "transitions to 'one_step_transferring'" do
          conversation = create :in_progress_hold_conversation_with_calls

          conversation.initiate_one_step_transfer!
          conversation.state.should == "one_step_transferring"
        end
      end
    end

    describe '#complete_one_step_transfer!' do
      before do
        @conversation = create :in_progress_conversation_with_calls
        @conversation.initiate_one_step_transfer!
        @conversation.complete_one_step_transfer!
      end

      it 'transitions to "in_progress"' do
        @conversation.state.should == 'in_progress'
      end

      it 'logs a one step transfer completed event' do
        event = Events::CompleteOneStepTransfer.last
        event.should be
      end
    end

    describe '#fail_one_step_transfer!' do
      before do
        @conversation = create :in_progress_conversation_with_calls
        @conversation.initiate_one_step_transfer!
        @conversation.active_agent_leg.terminate!
        @conversation.fail_one_step_transfer!
      end

      it 'transitions to "leaving_voicemail"' do
        @conversation.state.should == 'leaving_voicemail'
      end

      it 'logs a one step transfer failed event' do
        event = Events::FailOneStepTransfer.last
        event.should be
      end
    end

    describe '#initiate_two_step_transfer!' do
      context "from 'in_progress'" do
        before do
          @conversation = create :in_progress_conversation_with_calls
          @conversation.initiate_two_step_transfer!
        end

        it 'transitions to "two_step_transferring"' do
          @conversation.state.should == 'two_step_transferring'
        end

        it 'logs a two step transfer initiated event' do
          event = Events::InitiateTwoStepTransfer.last
          event.should be
        end
      end

      context "from 'in_progress_hold'" do
        it "transitions to 'two_step_transferring_hold'" do
          conversation = create :in_progress_hold_conversation_with_calls

          conversation.initiate_two_step_transfer!
          conversation.state.should == "two_step_transferring_hold"
        end
      end
    end

    describe '#complete_two_step_transfer!' do
      context "from two_step_transferring" do
        before do
          @conversation = create :in_progress_conversation_with_calls
          @conversation.initiate_two_step_transfer!
          @conversation.complete_two_step_transfer!
        end

        it 'transitions to "in_progress_two_step_transfer"' do
          @conversation.state.should == 'in_progress_two_step_transfer'
        end

        it 'logs a two step transfer completed event' do
          event = Events::CompleteTwoStepTransfer.last
          event.should be
        end
      end

      context "from two_step_transferring_hold" do
        before do
          @conversation = create :two_step_transferring_hold_conversation_with_calls
          @conversation.complete_two_step_transfer!
        end

        it 'transitions to "in_progress_two_step_transfer_hold"' do
          @conversation.state.should == 'in_progress_two_step_transfer_hold'
        end

        it 'logs a two step transfer completed event' do
          event = Events::CompleteTwoStepTransfer.last
          event.should be
        end
      end
    end

    describe '#customer_left_two_step_transfer!' do
      context "from 'in_progress_two_step_transfer' conversation" do
        before do
          @conversation = create :in_progress_two_step_transfer_with_calls
          @conversation.customer_left_two_step_transfer!
        end

        it 'transitions to "agents_only"' do
          @conversation.should be_agents_only
        end

        it 'logs a customer left two step transfer event' do
          event = Events::CustomerLeftTwoStepTransfer.last
          event.should be
        end
      end

      context "from 'in_progress_two_step_transfer_hold' conversation" do
        before do
          @conversation = create :in_progress_two_step_transfer_hold_with_calls
          @conversation.customer_left_two_step_transfer!
        end

        it 'transitions to "agents_only"' do
          @conversation.should be_agents_only
        end
      end
    end

    describe '#leave_two_step_transfer!' do
      context "from 'in_progress_two_step_transfer' conversation" do
        before do
          @conversation = create :in_progress_two_step_transfer_conversation
          @conversation.leave_two_step_transfer!
        end

        it 'transitions to "in_progress"' do
          @conversation.state.should == 'in_progress'
        end

        it 'logs a leave two step transfer event' do
          event = Events::LeaveTwoStepTransfer.last
          event.should be
        end
      end

      context "from 'in_progress_two_step_transfer_hold' conversation" do
        before do
          @conversation = create :conversation, state: 'in_progress_two_step_transfer_hold'
          @conversation.leave_two_step_transfer!
        end

        it 'transitions to "in_progress"' do
          @conversation.state.should == 'in_progress_hold'
        end
      end
    end

    describe '#fail_two_step_transfer!' do
      context "from 'two_step_transferring' conversation" do
        before do
          @conversation = create :in_progress_conversation_with_calls
          @conversation.initiate_two_step_transfer!
          @conversation.fail_two_step_transfer!
        end

        it 'transitions to "in_progress"' do
          @conversation.state.should == 'in_progress'
        end

        it 'logs a two step transfer failed event' do
          event = Events::FailTwoStepTransfer.last
          event.should be
        end
      end

      context "from 'two_step_transferring_hold' conversation" do
        before do
          @conversation = create :two_step_transferring_hold_conversation_with_calls
          @conversation.fail_two_step_transfer!
        end

        it 'transitions to "in_progress"' do
          @conversation.state.should == 'in_progress_hold'
        end
      end
    end

    describe '#leave_voicemail!' do
      before do
        @conversation = create :in_progress_conversation_with_calls
        @conversation.leave_voicemail!
      end

      it 'transitions to "leaving_voicemail"' do
        @conversation.state.should == 'leaving_voicemail'
      end

      it 'logs a leave voicemail event' do
        event = Events::LeaveVoicemail.last
        event.should be
      end
    end

    describe '#terminate!' do
      before do
        @conversation = create :in_progress_conversation
        @conversation.terminate!
      end

      it 'transitions to "terminated"' do
        @conversation.state.should == 'terminated'
      end

      it 'logs a terminated event' do
        event = Events::Terminate.last
        event.should be
      end
    end

    describe "#initiate_hold" do
      context "given 'in_progress' conversation" do
        before do
          @conversation = create :in_progress_conversation
          @conversation.initiate_hold!
        end

        it 'transitions to "initiating_hold"' do
          @conversation.should be_initiating_hold
        end
      end

      context "given 'in_progress_two_step_transfer' conversation" do
        before do
          @conversation = create :in_progress_two_step_transfer_conversation
          @conversation.initiate_hold!
        end

        it 'transitions to "initiating_hold"' do
          @conversation.should be_initiating_two_step_transfer_hold
        end
      end
    end

    describe "#complete_hold" do
      context "given 'initiating_hold' conversation" do
        before do
          @conversation = create :initiating_hold_conversation
          create :call, conversation: @conversation
          @conversation.complete_hold!
        end

        it 'transitions to "in_progress_hold"' do
          @conversation.should be_in_progress_hold
        end
      end

      context "given 'initiating_two_step_transfer_hold' conversation" do
        before do
          @conversation = create :conversation, state: 'initiating_two_step_transfer_hold'
          create :call, conversation: @conversation
          @conversation.complete_hold!
        end

        it 'transitions to "in_progress_hold"' do
          @conversation.should be_in_progress_two_step_transfer_hold
        end
      end
    end

    describe "#initiate_resume" do
      context "given 'in_progress_hold' conversation" do
        it "transitions to 'initiating_resume'" do
          conversation = create :in_progress_hold_conversation
          conversation.initiate_resume!

          conversation.should be_initiating_resume
        end
      end

      context "given 'in_progress_two_step_transfer_hold' conversation" do
        it "transitions from 'in_progress_two_step_transfer_hold' to 'initiating_two_step_transfer_resume'" do
          conversation = create :conversation, state: 'in_progress_two_step_transfer_hold'
          conversation.initiate_resume!

          conversation.should be_initiating_two_step_transfer_resume
        end
      end
    end

    describe "#complete_resume" do
      context "given an 'initiating_resume' conversation" do
        it "transitions from 'initiating_resume' to 'in_progress'" do
          conversation = create :initiating_resume_conversation
          create :call, conversation: conversation
          conversation.complete_resume!

          conversation.should be_in_progress
        end
      end

      context "given an 'initiating_two_step_transfer_resume' conversation" do
        it "transitions from 'initiating_two_step_transfer_resume' to 'in_progress_two_step_transfer'" do
          conversation = create :conversation, state: 'initiating_two_step_transfer_resume'
          create :call, conversation: conversation
          conversation.complete_resume!

          conversation.should be_in_progress_two_step_transfer
        end
      end
    end
  end
end
