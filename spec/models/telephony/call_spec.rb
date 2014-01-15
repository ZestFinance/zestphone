require 'spec_helper'

module Telephony
  describe Call do
    describe '#make!' do
      context 'when calling the initiator' do
        before do
          @call = create(:call, number: '222-222-2222')

          @sid = '2'
          call = double 'call', sid: @sid
          provider = double('Provider')
          provider.stub(:call).with(@call.id, @call.number, @call.caller_id).and_return(call)
          Telephony.stub(:provider).and_return(provider)

          @call.make!
        end

        it 'calls the initiator using a telephony provider' do
          @call.reload
          @call.sid.should == @sid
        end
      end

      context 'when calling a non-whitelisted number' do
        before do
          @existing_whitelist = Telephony.whitelist
          Telephony.whitelist = []
          @call = create :call, number: '555-555-5555'

          @sid = '1'
          call = double 'call',
            sid: @sid
          provider = double 'provider'
          provider
            .should_receive(:call)
            .and_return(call)
          provider.stub(:uncallable_number)
          Telephony.stub(:provider).and_return(provider)

          @call.make!
        end

        after do
          Telephony.whitelist = @existing_whitelist
        end

        it "uses the number's non-whitelisted area code when determining the caller id" do
          @call.reload
          @call.sid.should == @sid
        end
      end

      after do
        Telephony.unstub :provider
      end
    end

    describe '#dial_into_conference!' do
      context "when calling the transferred to agent" do
        before do
          @caller_id = '1234567890'
          @participant = create(:transferred_participant, number: '222-222-2222')
          @participant.stub(:caller_id).and_return(@caller_id)

          @sid = '1'
          call = double 'call', sid: @sid
          provider = double('Provider')
          provider
            .stub(:dial_into_conference)
            .with(@participant.id, @participant.number, @caller_id)
            .and_return(call)
          Telephony
            .stub(:provider)
            .and_return(provider)

          @participant.dial_into_conference!
        end

        it 'dials the agent into the conference' do
          @participant.reload
          @participant.sid.should == @sid
        end
      end

      context 'when calling a non-whitelisted number' do
        before do
          @existing_whitelist = Telephony.whitelist
          Telephony.whitelist = []
          @call = create :call

          @sid = '1'
          call = double 'call'
          call.stub(:sid).and_return(@sid)
          provider = double 'provider'
          provider
            .stub(:dial_into_conference)
            .and_return(call)
          provider.stub(:uncallable_number)
          Telephony
            .stub(:provider)
            .and_return(provider)

          @call.dial_into_conference!
        end

        after do
          Telephony.whitelist = @existing_whitelist
        end

        it "uses the number's non-whitelisted area code when determining the caller id" do
          @call.reload
          @call.sid.should == @sid
        end
      end

      after do
        Telephony.unstub :provider
      end
    end

    describe "#recorded?" do
      context "given an initiator call" do
        let(:agent) {create :agent}
        before do
          @call = create :call, agent: agent
        end

        it 'returns false' do
          @call.should_not be_recorded
        end
      end

      context "given a transferred call" do
        let(:agent) {create :agent}
        before do
          @call = create :transferred_participant, agent: agent
        end

        it 'returns false' do
          @call.should_not be_recorded
        end
      end

      context "given any other call" do
        before do
          call = create :call
          @call = create :participant, :conversation => call.conversation
        end

        it 'returns true' do
          @call.should be_recorded
        end
      end
    end

    describe '#save' do
      context 'on create' do
        context 'and with no initial state' do
          before do
            @call = build :call
            @call.save
          end

          it 'defaults its state to "not_initiated"' do
            @call.reload
            @call.state.should == 'not_initiated'
          end
        end

        context 'and with an initial state' do
          before do
            @call = build :call, state: 'terminated'
            @call.save
          end

          it 'does not reset its state to not_initiated' do
            @call.reload
            @call.state.should_not == 'not_initiated'
          end
        end
      end
    end

    describe '#answer!' do
      before do
        @call = create :call, :state => :connecting
        @expected_time = Time.zone.now
        Time.zone.stub(:now).and_return(@expected_time)

        @call.answer!

        @call.reload
      end

      it 'updates its state to "in_progress"' do
        @call.state.should == 'in_progress'
      end

      it 'sets its connected at timestamp' do
        @call.connected_at.to_s.should == @expected_time.to_s
      end
    end

    describe '#terminate!' do
      context 'by default' do
        before do
          @call = create :call

          @expected_time = Time.zone.now
          Time.zone.stub(:now => @expected_time)

          @call.terminate!
          @call.reload
        end

        it 'sets its state to "terminated"' do
          @call.state.should == 'terminated'
        end

        it 'sets its terminated timestamp' do
          @call.terminated_at.to_s.should == @expected_time.to_s
        end

      end

      context 'In a conversation, customer leg hangs up' do

        before do
          ActiveRecord::Base.observers.enable :all
          Telephony::PusherEventPublisher.stub(:push)
          @convo = create :in_progress_conversation
          @call1 = create :active_agent_leg, conversation_id: @convo.id
          @call2 = create :customer_leg, conversation_id: @convo.id
          @call1.agent.update_attribute(:status, 'on_a_call')
        end

        after do
          ActiveRecord::Base.observers.disable :all
        end

        it 'Agent should be not available' do
          @call2.terminate!
          @call1.agent.reload
          @call1.agent.should be_not_available
        end

      end


      context 'given a one step transfer call' do
        before do
          @call = create :one_step_transfer_call
        end

        it 'does not hangup on the initiator' do
          Telephony
          .provider
          .should_not_receive(:hangup)

          @call.terminate!
        end
      end

      context 'given a two step transfer call' do
        before do
          @call = create :two_step_transfer_call, state: :in_conference
        end

        after do
          Telephony.unstub :provider
        end

        context 'with two participants' do
          context 'and the initiator hangs up' do
            before do
              @participant = create :call, conversation: @call.conversation, state: :in_conference
              @call.reload
            end

            it "hangs up the other participant" do
              provider = double 'Provider'
              provider.should_receive(:hangup).with(@participant.sid)
              Telephony.stub(:provider).and_return(provider)

              @call.terminate!
            end
          end

          context 'and the participant hangs up' do
            before do
              @participant = create :participant, conversation: @call.conversation
              @call.reload
            end

            it "hangs up on the initiator" do
              provider = double 'Provider'
              provider.should_receive(:hangup).with(@call.sid)
              Telephony.stub(:provider).and_return(provider)

              @participant.terminate!
            end
          end
        end

        context 'with three participants' do
          context 'and the initiator hangs up' do
            before do
              create :call, conversation: @call.conversation
              create :active_agent_leg, conversation: @call.conversation
              @call.reload
            end

            it "does not hang up the other participants" do
              provider = double 'Provider'
              provider.should_not_receive(:hangup)
              Telephony.stub(:provider).and_return(provider)

              @call.terminate!
            end
          end

          context 'and the initiator hangs up, then a participant hangs up' do
            before do
              @participants = [
                create(:call, conversation: @call.conversation, state: :in_conference),
                create(:active_agent_leg, conversation: @call.conversation, state: :in_conference)
              ]
              @call.reload
            end

            it "hangs up the other participant" do
              first_participant, second_participant = @participants
              provider = double 'Provider'
              provider.should_receive(:hangup).with(second_participant.sid)
              Telephony.stub(:provider).and_return(provider)

              @call.terminate!
              first_participant.terminate!
            end
          end

          context 'and one of the participants hangs up' do
            before do
              @participant = create :call, conversation: @call.conversation
              create :active_agent_leg, conversation: @call.conversation
              @call.reload
            end

            it "does not hang up the initiator or the other participant" do
              provider = double 'Provider'
              provider.should_not_receive(:hangup)
              Telephony.stub(:provider).and_return(provider)

              @participant.terminate!
            end
          end
        end
      end

      context 'given an attempted transfer' do
        before do
          @conversation = create :conversation, state: :two_step_transferring
          @agent1   = create :call,
            conversation: @conversation,
            state: :in_conference,
            agent: create(:agent)
          @customer = create :call,
            conversation: @conversation,
            state: :in_conference
          @agent2   = create :call,
              conversation: @conversation,
              state: :connecting,
              agent: create(:agent)
        end


        context 'when the transferred participant does not answer' do
          before do
            @agent2.no_answer!
            @conversation.reload
          end

          context 'and the customer hangs up' do
            after do
              Telephony.unstub :provider
            end

            it 'hangs up on the initiator' do
              provider = double 'Provider'
              provider.should_receive(:hangup).with(@agent1.sid)
              Telephony.stub(:provider).and_return(provider)

              @customer.terminate!
            end
          end
        end
      end
    end

    describe '#number' do
      before do
        @call = build :call
        @whitelisted_number = '1234567890'
        @existing_whitelist = Telephony.whitelist
        Telephony.whitelist = [@whitelisted_number]
      end

      subject { @call.number }

      after { Telephony.whitelist = @existing_whitelist }

      context 'given a call to a whitelisted number' do
        before { @call.number = @whitelisted_number }
        it { should == @whitelisted_number }
      end

      context 'given a call to a non-whitelisted number' do
        before { @call.number = '9999999999' }
        it { should == 'this-number-is-not-whitelisted' }
      end

      context 'given an agents call' do
        before { @call.agent = build :agent, phone_number: '1231231234' }
        it { should == @call.agent.phone_number }
      end
    end

    describe '#whitelisted_number?' do
      before do
        @existing_whitelist = Telephony.whitelist
      end

      after do
        Telephony.whitelist = @existing_whitelist
      end

      context 'given a call to a whitelisted number' do
        before do
          phone_number = '555-555-5555'
          Telephony.whitelist = [phone_number]
          @call = create :call, number: phone_number
        end

        it 'returns true' do
          @call.should be_whitelisted_number
        end
      end

      context 'given a call to a non-whitelisted number' do
        before do
          @call = create :call
          Telephony.whitelist = []
        end

        it 'returns false' do
          @call.should_not be_whitelisted_number
        end
      end

      context 'given an agents leg' do
        before do
          Telephony.whitelist = []
          agent = create :agent
          @call = create :call, agent: agent
        end

        it 'returns true' do
          @call.should be_whitelisted_number
        end
      end

      context 'given a customers leg' do
        before do
          Telephony.whitelist = []
          @call = create :call, agent: nil
        end

        it 'returns false' do
          @call.should_not be_whitelisted_number
        end
      end
    end

    describe '#record!' do
      context 'given a recording url and duration' do
        before do
          @call = create :call
          @recording_url = 'recording_url'
          @recording_duration = 0

          @call.record! RecordingUrl: @recording_url,
            RecordingDuration: @recording_duration

          @call.reload
        end

        it 'updates its recording url' do
          @call.recordings.last.url.should == @recording_url
        end

        it 'updates its recording duration' do
          @call.recordings.last.duration.should == @recording_duration
        end
      end

      context 'when not given a recording url and duration' do
        before do
          @call = create :call

          @recordings_count = @call.recordings.count
          @call.record!({})
          @call.reload
        end

        it 'does not create a recording' do
          @call.recordings.count.should == @recordings_count
        end

      end
    end

    describe '#redirect_to_dial' do
      before do
        @call = create :call
        provider = double 'provider'
        provider
          .should_receive(:redirect_to_dial)
          .with(@call.id, @call.sid)
        Telephony
          .stub(:provider)
          .and_return(provider)
      end

      it 'redirects the call to dial' do
        @call.redirect_to_dial
      end
    end

    describe '#redirect_to_conference' do
      before do
        @call = create :call
        provider = double 'provider'
        provider
          .should_receive(:redirect_to_conference)
          .with(@call.id, @call.sid)
        Telephony
          .stub(:provider)
          .and_return(provider)
      end

      it 'redirects the call to a conference' do
        @call.redirect_to_conference
      end
    end

    describe '#redirect_to_hold' do
      before do
        @call = create :call
        provider = double 'provider'
        provider
          .should_receive(:redirect_to_hold)
          .with(@call.id, @call.sid)
        Telephony
          .stub(:provider)
          .and_return(provider)
      end

      it 'redirects the call to a hold' do
        @call.redirect_to_hold
      end
    end

    describe '#agent?' do
      context 'given a call for a CSR' do
        let(:agent) {create :agent}
        before do
          @call = create :call, agent: agent
        end

        it 'returns true' do
          @call.should be_an_agent
        end
      end

      context 'given a call not for a CSR' do
        before do
          @call = create :call, agent: nil
        end

        it 'returns false' do
          @call.should_not be_an_agent
        end
      end
    end
  end
end
