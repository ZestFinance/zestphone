require 'spec_helper'

module Telephony
  module Events
    describe Base do
      describe '.log' do
        let(:conversation) { create :conversation }

        before do
          @count = Terminate.count
          @call_state = 'call_state'
          @agent = create :agent
          conversation.calls.create number: "1112223333",
            agent: @agent

          Base.log name: :terminate,
            data: {
              call_state: @call_state,
              conversation_id: conversation.id,
              call_id: conversation.calls.first.id,
              conversation_state: "terminated"
            }
        end

        it 'creates an event of the given type' do
          Terminate.count.should == @count + 1
        end

        it 'sets its attributes from the given data' do
          event = Terminate.last
          event.should be
          event.call_state.should == @call_state
        end

        it 'serializes the agent messages into message data' do
          event = Terminate.last
          event.message_data.should == [agent: @agent]
        end
      end

      describe '.find_last_for_agent' do
        before do
          @agent = create :on_a_call_agent
        end

        context 'agent has no calls' do
          it 'returns the default event' do
            Base.find_last_for_agent(@agent).should be_an(InitializeWidget)
          end
        end

        context 'agent has calls' do
          context 'but with no events' do
            before do
              @conversation = create :conversation
              @call = create :call, conversation: @conversation, agent: @agent
            end

            it 'returns the default event' do
              Base.find_last_for_agent(@agent).should be_an(InitializeWidget)
            end
          end

          context 'but with no publishable events' do
            before do
              @conversation = create :conversation
              @call = create :call, conversation: @conversation, agent: @agent

              non_publishable_event = create :answer_event, conversation: @conversation
            end

            it 'returns the default event' do
              Base.find_last_for_agent(@agent).should be_an(InitializeWidget)
            end
          end

          context 'with publishable events for agent2' do
            before do
              class Base
                attr_accessible :type
              end

              class Dummy < Base
                def publishable?
                  true
                end

                def agent_messages
                  [{ agent: agent2 }]
                end
              end
            end

            it 'returns the default event' do
              agent1 = create :on_a_call_agent
              agent2 = create :on_a_call_agent
              conversation = create :conversation
              agent1_call = create :call, conversation: conversation, agent: agent1
              customer = create :call, conversation: conversation
              agent2_call = create :call, conversation: conversation, agent: agent2
              publishable_event = conversation.events.create type: 'Telephony::Events::Dummy'

              Base.find_last_for_agent(agent1).should be_an(InitializeWidget)
            end
          end

          context 'with publishable events for agent1' do
            it 'returns the last event for agent1' do
              agent1 = create :on_a_call_agent
              conversation = create :conversation
              create :call, conversation: conversation, agent: agent1
              create :call, conversation: conversation
              publishable_event = build :conversation_start_event, conversation: conversation

              publishable_event.update_attributes message_data: publishable_event.agent_messages

              Base.find_last_for_agent(agent1).should be_an(Start)
            end
          end
        end

        context "given an agent that's not on a call" do
          before do
            @agent = create :available_agent

            @event = Base.find_last_for_agent @agent
          end

          it 'returns a new default event' do
            @event.should be_an(InitializeWidget)
          end
        end
      end

      describe '#new_default_event' do
        before do
          @event = Base.new_default_event
        end

        it 'returns a new initialize widget event' do
          @event.should be_an(InitializeWidget)
        end
      end

      describe '#publish' do
        let(:event_publisher) { mock(:event_publisher) }

        context "given a publishable event" do
          let(:event) { build(:publishable_event) }

          context "with an agent" do
            before do
              event.message_data = event.agent_messages
              PusherEventPublisher
                .should_receive(:publish)
                .with(channel: "csrs-#{event.call.agent.csr_id}",
                      name: event.class.name.demodulize,
                      data: {
                        event_id: event.id,
                        conversation_id: event.conversation.id,
                        conversation_state: event.conversation.state,
                        call_id: event.call.id,
                        number: event.conversation.customer.number,
                        loan_id: event.conversation.loan_id,
                        owner: true
                      })
            end

            it "asks the event publisher to publish an event" do
              event.publish
            end
          end

          context "with no agent" do
            before do
              event.call.stub(:agent).and_return nil
              PusherEventPublisher.should_not_receive(:publish)
            end

            it "does not ask the event publisher to publish an event" do
              event.publish
            end
          end
        end

        context 'given a non-publishable event' do
          let(:event) { build(:non_publishable_event) }

          before do
            PusherEventPublisher.should_not_receive(:publish)
          end

          it "does not ask the event publisher to publish an event" do
            event.publish
          end
        end
      end

      describe '#publishable?' do
        context 'by default' do
          before do
            @event = Base.new
          end

          it 'returns false' do
            @event.should_not be_publishable
          end
        end
      end

      describe '#default_data' do
        let(:event) { create(:publishable_event) }

        it 'returns the event data' do
          event.default_data[:event_id].should == event.id
          event.default_data[:conversation_id].should == event.conversation.id
          event.default_data[:conversation_state].should == event.conversation.state
          event.default_data[:call_id].should == event.call.id
          event.default_data[:number].should == event.conversation.customer.number
          event.default_data[:loan_id].should == event.conversation.loan_id
          event.default_data[:owner].should == true
        end
      end

      describe "#agent2" do
        it "returns the last call's agent" do
          agent1 = create :agent
          agent2 = create :agent
          conversation = create :conversation
          agent1_call = create :call, conversation: conversation, agent: agent1
          customer = create :call, conversation: conversation
          agent2_call = create :call, conversation: conversation, agent: agent2, state: 'terminated'
          event = create(:two_step_transfer_failed_event, conversation: conversation)

          event.send(:agent2).should == agent2
        end
      end

      describe '#republish_only_for' do
        context 'given an event that was published for multiple agents' do
          before do
            @event = create :two_step_transfer_failed_event
          end

          context 'and the current agent received the event' do
            before do
              @agent = @event.agent2
              PusherEventPublisher.should_receive :publish
            end

            it 'republishes the event for the current agent' do
              @event.republish_only_for @agent
            end
          end

          context 'and the current agent did not receive the event' do
            before do
              @agent = create :agent
              PusherEventPublisher.should_not_receive :publish
            end

            it 'does not republish the event for the current agent' do
              @event.republish_only_for @agent
            end
          end
        end
      end
    end

    describe Connect do
      describe '#agent_messages' do
        context "for agent1" do
          let(:event) { build(:agent_call_connect_event) }

          before do
            @agent1 = event.agent_messages.first[:agent]
          end

          it 'returns agent1' do
            @agent1.should == event.conversation.first_active_agent
          end

          it 'sets owner to true' do
            event.agent_messages.first[:data][:owner].should be_true
          end
        end

        context "for agent2" do
          let(:event) { build :agent_call_connect_event }

          before do
            event.should_receive(:agent1).and_return('something not equal')
          end

          it 'sets owner to false' do
            event.agent_messages.first[:data][:owner].should be_false
          end
        end
      end

      describe '#publishable?' do
        context 'given a call connect event' do
          context 'for an agent' do
            let(:event) { build(:agent_call_connect_event) }

            it 'returns true' do
              event.should be_publishable
            end
          end

          context 'for a non agent' do
            let(:event) { build(:borrower_call_connect_event) }

            it 'returns false' do
              event.should_not be_publishable
            end
          end

          context 'for a transferring conversation' do
            let(:event) { build(:agent_call_connect_event,
                                conversation_state: 'one_step_transferring') }

            it 'returns false' do
              event.should_not be_publishable
            end
          end
        end

        context 'given a conversation connect event' do
          let(:event) { build(:conversation_connect_event) }

          it 'returns false' do
            event.should_not be_publishable
          end
        end
      end
    end

    describe Start do
      describe '#agent_messages' do
        let(:event) { build :conversation_start_event }

        before do
          @agent1 = event.agent_messages.first[:agent]
        end

        it 'returns agent1' do
          @agent1.should == event.conversation.first_active_agent
        end
      end

      describe '#publishable?' do
        let(:event) { build(:conversation_start_event) }

        it 'returns true' do
          event.should be_publishable
        end
      end
    end

    describe CallAnswered do
      context "for an agent's call" do
        describe '#agent_messages' do
          context "for agent1" do
            let(:event) { build :conversation_answer_event }

            before do
              @agent1 = event.agent_messages.first[:agent]
            end

            it 'returns agent1' do
              @agent1.should == event.conversation.first_active_agent
            end

            it 'sets owner to true' do
              event.agent_messages.first[:data][:owner].should be_true
            end
          end

          context "for agent2" do
            let(:event) { build :conversation_answer_event }

            before do
              event.should_receive(:agent1).and_return('something not equal')
            end

            it 'sets owner to false' do
              event.agent_messages.first[:data][:owner].should be_false
            end
          end
        end

        describe '#publishable?' do
          let(:event) { build(:conversation_answer_event) }

          it 'returns true' do
            event.should be_publishable
          end
        end
      end

      context "for a customer's call" do
        describe '#publishable?' do
          let(:event) { build(:conversation_answer_event_for_customer) }

          it 'returns false' do
            event.should_not be_publishable
          end
        end
      end
    end

    describe Ended do
      describe '#agent_messages' do
        let(:event) { build(:csr_call_ended_event) }

        before do
          @agent = event.agent_messages.first[:agent]
        end

        it "returns the call's agent" do
          @agent.should == event.call.agent
        end
      end

      describe '#publishable?' do
        context 'given a call ended event' do
          context 'for a CSR' do
            let(:event) { build(:csr_call_ended_event) }

            it 'returns true' do
              event.should be_publishable
            end
          end

          context 'for a non CSR' do
            let(:event) { build(:borrower_call_ended_event) }

            it 'returns false' do
              event.should_not be_publishable
            end
          end
        end

        context 'given a conversation ended event' do
          let(:event) { build(:conversation_ended_event) }

          it 'returns false' do
            event.should_not be_publishable
          end
        end
      end
    end

    describe Transfer do
      describe '#publishable?' do
        let(:event) { build(:two_step_transfer_initiated_event) }

        it 'returns true' do
          event.should be_publishable
        end
      end

      describe '#agent_messages' do
        let(:event) { build(:two_step_transfer_initiated_event) }

        context 'for agent1' do
          before do
            @agent1 = event.agent_messages.first[:agent]
            @agent1_data = event.agent_messages.first[:data]
          end

          it 'returns agent1' do
            @agent1 == event.conversation.first_active_agent
          end

          it 'returns the event data' do
            @agent1_data[:transferrer].should be_true
            @agent1_data[:agent_name].should == event.conversation.second_active_agent.name
            @agent1_data[:agent_ext].should == event.conversation.second_active_agent.phone_ext
            @agent1_data[:agent_type].should == event.conversation.second_active_agent.csr_type
          end
        end

        context 'for agent2' do
          before do
            @agent2 = event.agent_messages.last[:agent]
            @agent2_data = event.agent_messages.last[:data]
          end

          it 'returns agent2' do
            @agent2.should == event.conversation.second_active_agent
          end

          it 'returns the event data' do
            @agent2_data[:transferrer].should be_false
            @agent2_data[:agent_name].should == event.conversation.first_active_agent.name
            @agent2_data[:agent_ext].should == event.conversation.first_active_agent.phone_ext
            @agent2_data[:agent_type].should == event.conversation.first_active_agent.csr_type
            @agent2_data[:owner].should == false
          end
        end
      end
    end

    describe LeaveTwoStepTransfer do
      describe '#publishable?' do
        let(:event) { build(:leave_two_step_transfer_event) }

        it 'returns true' do
          event.should be_publishable
        end
      end

      describe '#agent_messages' do
        let(:event) { build(:leave_two_step_transfer_event) }

        before do
          @agent = event.agent_messages.first[:agent]
        end

        it 'returns agent1' do
          @agent.should == event.conversation.first_active_agent
        end
      end
    end

    describe FailOneStepTransfer do
      let(:event) { build(:one_step_transfer_failed_event) }

      describe '#publishable?' do
        it 'returns true' do
          event.should be_publishable
        end
      end

      describe '#agent_messages' do
        context 'for agent1' do
          before do
            @agent1 = event.agent_messages.first[:agent]
            @agent1_data = event.agent_messages.first[:data]
          end

          it 'returns agent1' do
            @agent1.should == event.conversation.first_inactive_agent
          end

          it 'returns the event data' do
            @agent1_data[:transferrer].should be_true
            @agent1_data[:agent_name].should == event.conversation.transferee.name
            @agent1_data[:agent_ext].should == event.conversation.transferee.phone_ext
            @agent1_data[:agent_type].should == event.conversation.transferee.csr_type
          end
        end

      end

      describe '#agent1' do
        before do
          @agent1 = event.agent1
        end

        it "returns its conversation's first inactive agent" do
          @agent1.should == event.conversation.first_inactive_agent
        end
      end
    end

    describe LeaveVoicemail do
      describe '#publishable?' do
        let(:event) { build :leave_voicemail_event }

        it 'returns true' do
          event.should be_publishable
        end
      end

      describe '#agent_messages' do
        let(:event) { build :leave_voicemail_event }

        before do
          @agent_messages = event.agent_messages.first
        end

        it 'returns agent1' do
          @agent_messages[:agent].should == event.agent1
        end

        it 'returns agent2 data' do
          agent2 = event.agent2
          data = @agent_messages[:data]
          data[:agent_name].should == agent2.name
          data[:agent_ext].should == agent2.phone_ext
          data[:agent_type].should == agent2.csr_type
        end
      end
    end

    describe CompleteHold do
      context "conversation level event" do
        let(:event) { build :complete_hold_event }

        describe "#publishable?" do
          it { event.should be_publishable }
        end

        describe "#agent_messages" do
          context "when there is one agent" do
            it "publishes to first agent's channel" do
              first_agent = event.agent_messages.first[:agent]
              first_agent.should == event.agent1
            end

            it "does not publish for agent2" do
              event.agent_messages.size.should == 1
            end
          end

          context "when there are two agents" do
            before do
              @agent2_leg = build :active_agent_leg
              event.conversation.calls.concat([@agent2_leg])
              @agent2_msgs = event.agent_messages.last
            end

            it "publishes to second agent's channel" do
              second_agent = @agent2_msgs[:agent]
              second_agent.should == @agent2_leg.agent
            end

            it "sets owner to false" do
              @agent2_msgs[:data][:owner].should == false
            end
          end
        end
      end

      context "call level event" do
        let(:event) { build :complete_hold_event, call_id: 1 }

        describe "#publishable?" do
          it { event.should_not be_publishable }
        end
      end
    end

    describe CompleteResume do
      let(:event) { build :complete_resume_event }

      describe "#publishable?" do
        it { event.should be_publishable }
      end

      describe "#agent_messages" do
        context "when there is one agent" do
          it "publishes to first agent's channel" do
            first_agent = event.agent_messages.first[:agent]
            first_agent.should == event.agent1
          end

          it "does not publish for agent2" do
            event.agent_messages.size.should == 1
          end
        end

        context "when there are two agents" do
          before do
            @agent2_leg = build :active_agent_leg
            event.conversation.calls.concat([@agent2_leg])
            @agent2_msgs = event.agent_messages.last
          end

          it "publishes to second agent's channel" do
            second_agent = @agent2_msgs[:agent]
            second_agent.should == @agent2_leg.agent
          end

          it "sets owner to false" do
            @agent2_msgs[:data][:owner].should == false
          end
        end
      end
    end

    describe InitializeWidget do
      describe '#republish_only_for' do
        before do
          @agent = create :agent
          @event = InitializeWidget.new

          PusherEventPublisher.should_receive :publish
        end

        it 'republishes the event for the current agent' do
          @event.republish_only_for @agent
        end
      end
    end
  end
end
