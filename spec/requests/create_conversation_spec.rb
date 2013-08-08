require 'spec_helper'

describe 'Creating a conversation', :vcr do
  before do
    agent = create :agent, csr_type: 'B'
    attributes = {
      from:      '310-456-7890',
      to:        '310-765-4321',
      loan_id:   1,
      from_id:   agent.csr_id,
      from_type: 'csr'
    }
    @existing_whitelist = Telephony.whitelist
    Telephony.whitelist = [attributes[:from], attributes[:to]]
    @conversation_count = Telephony::Conversation.count

    xhr :post,
      '/zestphone/conversations',
      attributes
  end

  after do
    Telephony.whitelist = @existing_whitelist
  end

  it 'creates a new conversation' do
    Telephony::Conversation.count.should == @conversation_count + 1
  end

  it 'creates a new call' do
    Telephony::Call.count.should == 2
  end

  it 'returns the conversation as JSON' do
    conversation = Telephony::Conversation.last
    json = JSON response.body
    json['id'].should == conversation.id
  end
end
