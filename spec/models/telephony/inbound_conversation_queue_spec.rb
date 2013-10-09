require 'spec_helper'

module Telephony
  describe InboundConversationQueue do
    describe '.play_message' do
      before do
        @count = Conversation.count
        @from = '111-111-1111'
        @to = '222-222-2222'
        @call_sid = "call_sid"

        @conversation = InboundConversationQueue.play_message From: @from,
                                                              To: @to,
                                                              CallSid: @call_sid
      end

      it 'creates an inbound conversation' do
        Conversation.count.should == @count + 1
        conversation = Conversation.last
        conversation.should be_inbound
      end

      it "sets the conversation's number to the called number" do
        conversation = Conversation.last
        conversation.number.should == @to
      end

      it "sets the conversation's caller id to the called number" do
        conversation = Conversation.last
        conversation.caller_id.should == @to
      end

      it 'connects the conversation' do
        conversation = Conversation.last
        conversation.should be_playing_message
      end

      it 'creates the initial leg of the conversation' do
        conversation = Conversation.last
        conversation.should have(1).call
        call = conversation.calls.first
        call.number.should == @from
        call.sid.should == @call_sid
      end

      it 'answers the initial leg' do
        conversation = Conversation.last
        conversation.should have(1).call
        call = conversation.calls.first
        call.should be_in_progress
      end
    end

    describe '.play_closed_greeting' do
      before do
        @count = Conversation.count
        @from = '111-111-1111'
        @to = '222-222-2222'
        @call_sid = "call_sid"

        @conversation = InboundConversationQueue.play_closed_greeting From: @from,
                                                                      To: @to,
                                                                      CallSid: @call_sid
      end

      it 'creates an inbound conversation' do
        Conversation.count.should == @count + 1
        conversation = Conversation.last
        conversation.should be_inbound
      end

      it "sets the conversation's number to the called number" do
        conversation = Conversation.last
        conversation.number.should == @to
      end

      it "sets the conversation's caller id to the called number" do
        conversation = Conversation.last
        conversation.caller_id.should == @to
      end

      it 'sets the conversation to closed greetings' do
        conversation = Conversation.last
        conversation.should be_terminated
      end

      it 'creates customer leg of the conversation' do
        conversation = Conversation.last
        conversation.should have(1).call
        call = conversation.calls.first
        call.number.should == @from
        call.sid.should == @call_sid
        call.should be_terminated
      end
    end

    describe '.reject' do
      before do
        @count = Conversation.count
        @from = '111-111-1111'
        @to = '222-222-2222'
        @call_sid = "call_sid"

        @conversation = InboundConversationQueue.reject From: @from,
                                                        To: @to,
                                                        CallSid: @call_sid
      end

      it 'creates an inbound conversation' do
        Conversation.count.should == @count + 1
        conversation = Conversation.last
        conversation.should be_inbound
      end

      it "sets the conversation's number to the called number" do
        conversation = Conversation.last
        conversation.number.should == @to
      end

      it "sets the conversation's caller id to the called number" do
        conversation = Conversation.last
        conversation.caller_id.should == @to
      end

      it 'sets the conversation to closed greetings' do
        conversation = Conversation.last
        conversation.should be_terminated
      end

      it 'creates customer leg' do
        conversation = Conversation.last
        conversation.should have(1).call
        call = conversation.calls.first
        call.number.should == @from
        call.sid.should == @call_sid
        call.should be_terminated
      end

      it 'creates a rejected event for the customer leg' do
        Telephony::Events::Reject.where(call_id: Telephony::Call.last.id).should be_exists
      end
    end

    describe '.dequeue' do
      context 'given a queue with a conversation' do
        before do
          @conversation = create :enqueued_conversation
          InboundConversationQueue.should_receive(:oldest_queued_conversation).and_return(@conversation)
          @agent = create :available_agent, csr_id: 123
          Telephony
            .provider
            .stub(:redirect_to_inbound_connect)
        end

        it 'puts the agent on a call' do
          @inbound_conversation = InboundConversationQueue.dequeue 123

          @agent.reload.should be_on_a_call
        end

        it 'redirects the customer inbound connect' do
          @conversation.customer.should_receive(:redirect_to_inbound_connect)

          @inbound_conversation = InboundConversationQueue.dequeue 123
        end

        it 'dequeues the next inbound call' do
          @inbound_conversation = InboundConversationQueue.dequeue 123

          @inbound_conversation[:id].should == @conversation.id
          @inbound_conversation[:customer_number].should == @conversation.customer.number
          @inbound_conversation[:pop_url].should be_nil
        end

        context "given a call with an associated pop url" do
          before do
            finder = mock()
            finder.stub(:find).with(@conversation.customer.sanitized_number).and_return('/foo')
            Telephony.pop_url_finder = finder
            @inbound_conversation = InboundConversationQueue.dequeue 123
          end

          after do
            Telephony.pop_url_finder = nil
          end

          it "sets the pop url" do
            JSON(@inbound_conversation.to_json)["pop_url"].should == "/foo"
          end
        end
      end

      context 'given an agent on a call' do
        before do
          @agent = create :on_a_call_agent, csr_id: 123
        end

        it 'raises an agent error exception' do
          expect {
            InboundConversationQueue.dequeue 123
          }.to raise_error(Telephony::Error::AgentOnACall)
        end
      end

      context 'given an empty queue' do
        it 'raises an empty queue exception' do
          agent = create :available_agent, csr_id: 123

          expect {
            InboundConversationQueue.dequeue 123
          }.to raise_error(Telephony::Error::QueueEmpty)
        end
      end
    end

    describe '.oldest_queued_conversation' do
      before do
        @conversation2 = create :enqueued_conversation
        @conversation1 = create :enqueued_conversation, created_at: (@conversation2.created_at - 1.second)
      end

      it 'should set the state of the dequeued call to connecting' do
        InboundConversationQueue.oldest_queued_conversation
        @conversation1.reload.should be_connecting
      end

      it 'should return the oldest first' do
        InboundConversationQueue.oldest_queued_conversation.should == @conversation1
      end

      it 'should return the newest second' do
        InboundConversationQueue.oldest_queued_conversation.should == @conversation1
        InboundConversationQueue.oldest_queued_conversation.should == @conversation2
      end

      it 'should return nothing when it is empty' do
        InboundConversationQueue.oldest_queued_conversation.should == @conversation1
        InboundConversationQueue.oldest_queued_conversation.should == @conversation2
        InboundConversationQueue.oldest_queued_conversation.should == nil
      end
    end
  end
end
