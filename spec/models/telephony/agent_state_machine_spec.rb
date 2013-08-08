require 'spec_helper'

module Telephony
  describe AgentStateMachine do
    describe '#status' do
      before do
        @agent = create :agent
      end

      it 'defaults to "offline"' do
        @agent.status.should == Agent::OFFLINE
      end
    end

    describe '#available!' do
      context 'given an offline agent' do
        before do
          @agent = create :agent

          @agent.available!

          @agent.reload
        end

        it 'transitions into available status' do
          @agent.status.should == Agent::AVAILABLE
        end
      end
    end

    describe '#offline!' do
      context "given an available agent" do
        before do
          @agent = create :available_agent

          @agent.offline!

          @agent.reload
        end

        it 'transitions into offline status' do
          @agent.status.should == Agent::OFFLINE
        end
      end
    end

    describe '#on_a_call!' do
      context 'given an available agent' do
        before do
          @agent = create :available_agent

          @agent.on_a_call!

          @agent.reload
        end

        it 'transitions into on a call status' do
          @agent.status.should == Agent::ON_A_CALL
        end
      end
    end

    describe '#not_available!' do
      context 'given a agent on a call' do
        before do
          @agent = create :on_a_call_agent

          @agent.not_available!

          @agent.reload
        end

        it 'transitions to not available' do
          @agent.status.should == Agent::NOT_AVAILABLE
        end
      end
    end
  end

  describe '#after_transition' do
    before do
      @subscriber = ActiveSupport::Notifications.subscribe("telephony.agent_status_change") do |*args|
        @event = ActiveSupport::Notifications::Event.new(*args)
      end
    end

    after do
      ActiveSupport::Notifications.unsubscribe(@subscriber)
    end

    context "when the status changes" do
      before do
        @agent = create :offline_agent
        @agent.available
      end

      it "publishes the status change" do
        @event.should_not be_nil
        @event.payload[:agent_id].should == @agent.id
        @event.payload[:csr_id].should == @agent.csr_id
        @event.payload[:status].should == @agent.status
        @event.payload.should include(:timestamp)
      end
    end

    context "when status doesn't change" do
      before do
        agent = create :available_agent
        agent.available
      end

      it "does not publish the status change" do
        @event.should be_nil
      end
    end
  end
end
