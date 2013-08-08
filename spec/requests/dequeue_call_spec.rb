require 'spec_helper'

describe 'Dequeue an inbound call' do
  context "given there's an inbound call on hold" do
    before do
      conversation = create :conversation
      create :call, conversation: conversation
      create :available_agent, csr_id: 1
      Telephony::Call.any_instance.should_receive(:redirect_to_inbound_connect)
      Telephony::InboundConversationQueue.stub(:oldest_queued_conversation).and_return(conversation)

      fake_finder = 'fake_finder'
      Telephony.stub(:pop_url_finder).and_return(fake_finder)
      fake_finder.stub(:find).and_return('some_url')

      delete "/zestphone/inbound/front?csr_id=1"
    end

    it 'returns the dequeued call as JSON' do
      json = JSON response.body
      json['pop_url'].should == 'some_url'
    end
  end

  context "given there is NO inbound call on hold" do
    before do
      create :available_agent, csr_id: 1
      delete "/zestphone/inbound/front?csr_id=1"
    end

    it 'returns 404 Not Found' do
      response.should be_not_found
    end

    it 'returns an error message' do
      json = JSON response.body
      errors = json['errors']
      errors.should have(1).error
      errors.first.should =~ /queue is empty/i
    end
  end
end
