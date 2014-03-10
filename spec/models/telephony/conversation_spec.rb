require 'spec_helper'

module Telephony
  describe Conversation do
    describe '.clean_up!' do
      subject { described_class.clean_up! }
      let(:query) { described_class.where('state != \'terminated\'').count }
      let(:states) { described_class.state_machine.states.map(&:name) }
      let(:non_terminated_states) { states - [:terminated] }

      before :each do
        states.each do |state|
          create(:conversation, state: state, created_at: 49.hours.ago)
          create(:conversation, state: state)
        end
      end

      context 'default' do
        subject { described_class.clean_up! }

        it 'cleans up old conversations that are not terminated' do
          subject
          query.should == non_terminated_states.count
        end
      end

      context 'with logging' do
        subject { described_class.clean_up!(logger: logger, log: true) }
        let(:logger) { double("Rails.logger", info: true) }

        it 'logs every conversation that is being terminated' do
          logger.should_receive(:info).exactly(non_terminated_states.count).times
          subject
        end
      end

      context 'with dry run' do
        subject { described_class.clean_up!(dry_run: true) }

        it 'does not terminate conversations' do
          subject
          query.should == (non_terminated_states.count * 2)
        end
      end
    end

    describe '.begin!' do
      before do
        @from = '222-222-2222'
        @agent = create :agent, phone_number: @from
        @args = {
          from_type: 'csr',
          from_id: @agent.csr_id,
          from: @from,
          to_type: 'borrower',
          to_id: 2,
          to: '111-111-1111',
          loan_id: 1
        }
        @count = Conversation.count
        Telephony
          .provider
          .stub(:caller_id_for)
          .and_return('111')
        @sid = 'sid'
        Telephony
          .provider
          .stub(:call)
          .and_return(OpenStruct.new(sid: @sid))

        @conversation = Conversation.begin! @args
      end

      it 'creates  a conversation' do
        Conversation.count.should == @count + 1
      end

      it 'creates an agent leg for the conversation' do
        call = @conversation.calls.first
        call.should be_agent
        call.number.should == @args[:from]
        call.participant_id.should == @args[:from_id]
        call.participant_type.should == @args[:from_type]
        call.agent.should == @agent
      end

      it 'creates a customer leg for the conversation' do
        call = @conversation.calls.last
        call.should_not be_agent
        call.number.should == @args[:to]
        call.participant_id.should == @args[:to_id]
        call.participant_type.should == @args[:to_type]
      end

      it 'connects the conversation' do
        @conversation.should be_connecting
      end

      it 'connects the initiating call' do
        call = @conversation.calls.first
        call.should be_connecting
        call.sid.should == @sid
      end
    end

    describe "caller_id" do
      let(:args) do
        {
          from_type: 'csr',
          from_id: @agent.csr_id,
          from: '222-222-2222',
          to_type: 'borrower',
          to_id: 2,
          to: '111-111-1111',
          loan_id: 1
        }
      end
      let(:sid) { 'sid' }
      let(:outbound_caller_id) { "18888888888" }

      before do
        Telephony.provider.stub(:caller_id_for).and_return('111-111-1111')
        Telephony.provider.stub(:call).and_return(OpenStruct.new(sid: sid))
      end

      context "when generate caller id is true" do
        before do
          @agent = create :agent, generate_caller_id: true
          @conversation = Conversation.begin! args
        end

        it "will use the same area code as the customer's area code" do
          @conversation.caller_id.should == '111-111-1111'
        end
      end

      context "when generate caller id is false" do
        before do
          @agent = create :agent, generate_caller_id: false
          Telephony.provider.stub(:outbound_caller_id).and_return(outbound_caller_id)
          @conversation = Conversation.begin! args
        end

        it "will use the same area code as the customer's area code" do
          @conversation.caller_id.should == outbound_caller_id
        end
      end
    end

    describe '#terminate_conferenced_calls' do
      before do
        @calls = [
          build(:in_conference_call),
          build(:in_conference_call),
          build(:in_conference_call)
        ]
        @non_hungup_call = @calls.first
        @conversation = @non_hungup_call.conversation
        @conversation.calls = @calls

        provider_stub = 'stub'
        Telephony.stub(:provider).and_return(provider_stub)
        provider_stub.should_receive(:hangup).exactly(2).times
        provider_stub.should_not_receive(:hangup).with(@non_hungup_call.sid)

      end

      it 'calls hangup on all calls that are in_conference' do
        @conversation.terminate_conferenced_calls @non_hungup_call.id
      end

      it 'terminates all calls that are in_conference' do
        @conversation.terminate_conferenced_calls @non_hungup_call.id

        terminated_calls = @calls - [@non_hungup_call]

        @non_hungup_call.should be_in_conference
        terminated_calls.each { |call| call.should be_terminated }
      end
    end

    describe '#transfer!' do
      context 'by default' do
        before do
          @number = '111-111-1111'
          @transfer_id = '999'
          @conversation = create :conversation, state: 'in_progress'
          @call = create :active_agent_leg, conversation: @conversation
          @participant = create :in_progress_call, conversation: @conversation
          @agent = create :available_agent, csr_id: @transfer_id
          Telephony
            .provider
            .should_receive(:redirect_to_dial)

          @conversation.transfer! @transfer_id, true
          @conversation = Conversation.find @conversation.id
        end

        it 'transfers a call using its telephony provider' do
          @conversation.should be_one_step_transferring
        end

        it 'creates calls' do
          @conversation.should have(3).calls
        end
      end

      context 'given a conversation that is not in progress or in progress hold' do
        before do
          @conversation = create :conversation, state: 'in_progress_two_step_transfer'
        end

        it 'should return an error' do
          @conversation.transfer!(1, true).should be_false
          @conversation.errors[:base].should == ["Conversation already #{@conversation.state}"]
        end
      end

      context 'given a one-step transfer' do
        before do
          conversation = create :conversation, state: 'in_progress'
          call = create :active_agent_leg, conversation: conversation
          participant = create :in_progress_call, conversation: conversation
          number = '111-111-1111'
          agent = create :agent, phone_number: number
          Telephony
            .provider
            .should_receive(:redirect_to_dial)
            .with(participant.id, participant.sid)
            .and_return(true)

          @ok = conversation.transfer! agent.csr_id, true
        end

        it 'returns true' do
          @ok.should be_true
        end
      end

      context 'given a one-step transfer for a call that has terminated' do
        before do
          conversation = create :conversation, state: 'in_progress'
          @call = create :call, conversation: conversation
          create :participant, conversation: conversation
          agent = create :agent

          Telephony
            .provider
            .stub(:redirect_to_dial)
            .and_raise(Telephony::Error::Connection.new("Error message"))

          @ok = conversation.transfer! agent.csr_id, true
        end

        it 'returns false' do
          @ok.should be_false
        end

        it 'has a validation error' do
          @call.conversation.errors[:base].should have(1).error
        end
      end

      context 'given a one-step transfer to an offline agent' do
        before do
          @conversation = create :in_progress_conversation
          create :active_agent_leg, conversation: @conversation
          create :in_progress_call, conversation: @conversation
          offline_agent = create :offline_agent

          Telephony
            .provider
            .stub(:redirect_to_dial)
            .and_return(true)

          @conversation.transfer! offline_agent.csr_id, true
        end

        it 'transitions the conversation into leaving a voicemail' do
          @conversation.reload
          @conversation.should be_leaving_voicemail
        end

        it 'creates a straight to voicemail event' do
          @conversation.events.last(2).first.should be_kind_of(Telephony::Events::StraightToVoicemail)
        end
      end

      context 'given a successful two-step transfer' do
        before do
          call = double 'call', sid: 1
          provider = double('Provider')
          provider.stub(:dial_into_conference).and_return(call)
          Telephony.stub(:provider).and_return(provider)

          @conversation = create :conversation, state: 'in_progress'
          @call = create :active_agent_leg, conversation: @conversation
          @participant = create :participant, conversation: @conversation
          agent = create :available_agent

          Telephony
            .provider
            .should_receive(:redirect_to_conference)
            .with(@conversation.customer.id, @participant.sid)
            .and_return(true)

          @participants_count = @conversation.calls.count
          @ok = @conversation.transfer! agent.csr_id, false

          @conversation.reload
        end

        after do
          Telephony.unstub :provider
        end

        it "adds another participant to itself" do
          @conversation.calls.count.should == @participants_count + 1
        end

        it 'returns true' do
          @ok.should be_true
        end
      end

      context 'given a two step transfer for a call that has terminated' do
        before do
          @conversation = create :conversation, state: 'in_progress'
          @call = create :call, conversation: @conversation
          create :participant, conversation: @conversation
          agent = create :agent

          Telephony
            .provider
            .stub(:redirect_to_conference)
            .and_raise(Telephony::Error::Connection.new)

          @ok = @conversation.transfer! agent.csr_id, false
        end

        it 'returns false' do
          @ok.should be_false
        end

        it 'has a validation error' do
          @conversation.errors[:base].should have(1).error
        end
      end

      context 'given a two step transfer to an unavailable agent' do
        before do
          @conversation = create :conversation, state: 'in_progress'
          create :active_agent_leg, conversation: @conversation
          create :customer_leg, conversation: @conversation
          agent = create :not_available_agent

          @ok = @conversation.transfer! agent.csr_id, false
        end

        it 'returns false' do
          @ok.should be_false
        end

        it 'has a validation error' do
          @conversation.errors[:base].should have(1).error
          @conversation.errors[:base].first.should =~ /agent is unavailable/i
        end
      end

      context 'given a transfer for a conversation that has terminated' do
        before do
          @conversation = create :conversation, state: :terminated
          @call = create :call, conversation: @conversation
          create :participant, conversation: @conversation
          agent = create :agent

          @ok = @conversation.transfer! agent.csr_id, true
        end

        it 'returns false' do
          @ok.should be_false
        end

        it 'has a validation error' do
          @conversation.errors[:base].should have(1).error
        end
      end
    end

    describe '#as_json' do
      before do
        conversation = create :conversation
        conversation.calls.build
        conversation.calls.build
        conversation.calls.first.recordings.build

        @json = conversation.as_json
      end

      it 'includes the conversations calls and their recordings' do
        @json.should have_key(:calls)
        @json[:calls].should have(2).items
        @json[:calls].first.should have_key(:recordings)
        @json[:calls].first[:recordings].should have(1).item
      end
    end

    describe '.new' do
      before do
        @conversation = Conversation.new
      end

      it 'defaults its conversation type to "outbound"' do
        @conversation.should be_outbound
      end
    end

    describe '.create_inbound!' do
      before do
        @args = {
          number: 'number'
        }
        @count = Conversation.count

        @conversation = Conversation.create_inbound! @args
      end

      it 'creates a new inbound conversation' do
        Conversation.count.should == @count + 1
        @conversation.should be_inbound
      end

      it "sets the conversation's attributes" do
        @conversation.number.should == @args[:number]
      end
    end

    describe '.find_with_lock' do
      before do
        agent = create :agent
        @conversation = create :conversation
        create(:call, conversation: @conversation, agent: agent)
      end

      it 'yields the conversation' do
        Conversation.find_with_lock @conversation.id do |conversation|
          @yielded_conversation = conversation
        end

        @yielded_conversation.should == @conversation
      end
    end

    describe '.find_inbound_with_lock' do
      before do
        @conversation = create :conversation
      end

      it 'yields the conversation' do
        Conversation.find_inbound_with_lock @conversation.id do |conversation|
          @yielded_conversation = conversation
        end

        @yielded_conversation.should == @conversation
      end
    end

    describe '#check_for_successful_hold' do
      context 'given a conversation with the customer already on hold' do
        before do
          @conversation = create :initiating_hold_conversation
          @agent_leg = create(:active_agent_leg,
                 conversation: @conversation)
          create(:customer_leg,
                 state: 'in_progress_hold',
                 conversation: @conversation)
        end

        context 'when the agent has moved to a conference' do
          before do
            @agent_leg.conference!
          end

          it 'transitions to in_progress_hold' do
            @conversation.reload.state.should == 'in_progress_hold'
          end
        end

        context 'when the agent has not moved to a conference' do
          it 'does not transition' do
            @conversation.check_for_successful_hold

            @conversation.reload.state.should == 'initiating_hold'
          end
        end
      end

      context 'given a conversation with the agents already in a conference' do
        before do
          @conversation = create :initiating_hold_conversation
          create(:active_agent_leg,
                 state: 'in_conference',
                 conversation: @conversation)
          @customer_leg = create(:customer_leg,
                                 conversation: @conversation)
          create(:active_agent_leg,
                 state: 'in_conference',
                 conversation: @conversation)
        end

        context 'when the customer has transitioned to in_progress_hold' do
          before do
            @customer_leg.complete_hold!
          end

          it 'transitions to in_progress_hold' do
            @conversation.reload.state.should == 'in_progress_hold'
          end
        end

        context 'when the customer has not transitioned to in_progress_hold' do
          it 'does not transition' do
            @conversation.check_for_successful_hold

            @conversation.reload.state.should == 'initiating_hold'
          end
        end
      end
    end

    describe '#check_for_successful_resume' do
      before do
        @conversation = create :initiating_resume_conversation
        create(:active_agent_leg,
               state: 'in_conference',
               conversation: @conversation)
        @customer_leg = create(:customer_leg,
                               state: 'in_progress_hold',
                               conversation: @conversation)
      end

      context 'when the customer moves to a conference' do
        before do
          @customer_leg.conference!
        end

        it 'transitions to in_progress_hold' do
          @conversation.reload.state.should == 'in_progress'
        end
      end

      context 'when the customer has not moved to a conference' do
        it 'does not transition' do
          @conversation.check_for_successful_resume

          @conversation.reload.state.should == 'initiating_resume'
        end
      end
    end

    describe '#hold!' do
      context 'given a conversation in a non-transferable state' do
        before do
          @conversation = create :two_step_transferring_conversation
        end

        it 'raises an exception' do
          expect {
            @conversation.hold!
          }.to raise_error(StateMachine::InvalidTransition)
        end
      end

      context 'given a conversation with conference calls' do
        context 'with one agent' do
          before do
            @conversation = create :in_progress_conversation
            create(:active_agent_leg,
                   state: 'in_conference',
                   conversation: @conversation)
            create(:customer_leg,
                   state: 'in_conference',
                   conversation: @conversation)
          end

          it 'redirects the customer to the hold queue and the agent to a conference (so the agent hears hold music)' do
            @conversation.active_agent_leg.should_receive(:redirect_to_conference)
            @conversation.customer.should_receive(:redirect_to_hold)

            @conversation.hold!
          end
        end

        context 'with two agents' do
          before do
            @conversation = create :in_progress_two_step_transfer_conversation
            create(:active_agent_leg,
                   state: 'in_conference',
                   conversation: @conversation)
            create(:customer_leg,
                   state: 'in_conference',
                   conversation: @conversation)
            create(:active_agent_leg,
                   state: 'in_conference',
                   conversation: @conversation)
          end

          it 'redirects the customer to the hold queue and leaves the agents in the conference' do
            @conversation.active_agent_legs.each {|leg| leg.should_not_receive(:redirect_to_conference) }
            @conversation.customer.should_receive(:redirect_to_hold)

            @conversation.hold!
          end
        end
      end

      context 'given a customer as the parent call' do
        before do
          @conversation = create :in_progress_conversation
          create(:customer_leg,
                 conversation: @conversation)
          create(:active_agent_leg,
                 conversation: @conversation)
        end

        it "changes the conversation to initiating hold" do
          @conversation.active_agent_leg.stub(:redirect_to_conference)
          @conversation.hold!
          @conversation.reload.should be_initiating_hold
        end

        it 'redirects the agent to a conference' do
          @conversation.active_agent_leg.should_receive(:redirect_to_conference)
          @conversation.hold!
        end
      end

      context 'given an agent as the parent call' do
        before do
          @conversation = create :in_progress_conversation
          create(:active_agent_leg,
                 conversation: @conversation)
          create(:customer_leg,
                 conversation: @conversation)
        end

        it 'redirects the customer to the hold queue' do
          @conversation.customer.should_receive(:redirect_to_hold)
          @conversation.hold!
        end
      end
    end

    describe '#resume!' do
      context 'given a conversation in a non-resumable state' do
        before do
          @conversation = create :two_step_transferring_conversation
        end

        it 'raises an exception' do
          expect {
            @conversation.resume!
          }.to raise_error(StateMachine::InvalidTransition)
        end
      end

      context 'given a conversation with conference calls' do
        before do
          @conversation = create :in_progress_hold_conversation
          create(:active_agent_leg,
                 state: 'in_conference',
                 conversation: @conversation)
          create(:customer_leg,
                 state: 'in_progress_hold',
                 conversation: @conversation)
        end

        it 'redirects the customer to a conference' do
          @conversation.customer.should_receive(:redirect_to_conference)

          @conversation.resume!
        end
      end
    end

    describe '#active_agent_leg' do
      context 'given a conversation with active and inactive agent legs' do
        before do
          @conversation = create :conversation
          create(:inactive_agent_leg,
                 conversation: @conversation)
          create(:customer_leg,
                 conversation: @conversation)
          create(:active_agent_leg,
                 conversation: @conversation)

          @active_agent_leg = @conversation.active_agent_leg
        end

        it 'returns the active agent leg' do
          @active_agent_leg.should == @conversation.calls[2]
        end
      end
    end

    describe "#first_active_agent" do
      context "outbound call" do
        let(:agent1) { build :agent }
        let(:conversation) { build :outbound_conversation }

        before do
          conversation.calls.first.agent = agent1
        end

        it "returns the first call's agent" do
          conversation.first_active_agent.should == agent1
        end
      end
    end

    describe "#customer" do
      context "inbound call" do
        let(:conversation) { build :inbound_conversation }

        it "returns the first call leg" do
          conversation.customer.should == conversation.calls.first
        end
      end

      context "outbound call" do
        let(:conversation) { build :outbound_conversation }

        it "returns the second call leg" do
          conversation.customer.should == conversation.calls.second
        end
      end
    end

    describe "#child_call" do
      let(:conversation) { build :outbound_conversation }

      context "given a sid" do
        it "returns the call with that sid" do
          call = conversation.calls.first
          conversation.child_call(call.sid).should == call
        end
      end

      context "given nil" do
        it "returns the second active call" do
          call = conversation.calls.last
          conversation.child_call.should == call
        end
      end
    end

    describe '#first_inactive_agent' do
      context 'given a conversation with an inactive agent' do
        before do
          @agent = create :agent
          conversation = create :conversation
          call = create :call,
            agent: @agent,
            conversation: conversation
          call.terminate!

          @first_inactive_agent = conversation.first_inactive_agent
        end

        it 'returns the inactive agent' do
          @first_inactive_agent.should == @agent
        end
      end

      context 'given a conversation without an inactive agent' do
        before do
          agent = create :agent
          conversation = create :conversation
          call = create :call,
            agent: agent,
            conversation: conversation
          call.connect!

          @first_inactive_agent = conversation.first_inactive_agent
        end

        it 'returns nil' do
          @first_inactive_agent.should be_nil
        end
      end
    end
  end
end
