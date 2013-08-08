require 'spec_helper'

describe 'Initiating a transfer' do
  before do
    @conversation = create :conversation, state: :in_progress
    create :active_agent_leg, conversation: @conversation
    customer = create :in_progress_call, conversation: @conversation
    @agent = create :available_agent

    Telephony
      .provider
      .should_receive(:redirect_to_dial)
      .with(customer.id, customer.sid)
      .and_return(true)
    @transfer_type = 'one_step'

    post "/zestphone/conversations/#{@conversation.id}/transfers",
        transfer_type: @transfer_type,
        transfer_id: @agent.csr_id
  end

  it 'transfers the call' do
    @conversation.reload
    @conversation.should be_one_step_transferring
  end

  it 'returns a successful response' do
    response.should be_success
  end

  it 'returns an empty JSON object' do
    json = JSON response.body
    json.should be_empty
  end
end

describe 'Failing to transfer' do
  before do
    conversation = create :conversation, state: :in_progress
    create :active_agent_leg, conversation: conversation
    create :in_progress_call, conversation: conversation
    agent = create :available_agent

    Telephony
      .provider
      .stub(:redirect_to_conference)
      .and_raise(Telephony::Error::Connection.new('a failure message'))

    post "/zestphone/conversations/#{conversation.id}/transfers",
        transfer_id: agent.csr_id
  end

  it 'return a 422 failure response' do
    response.code.should == "422"
  end

  it 'returns an error message as JSON' do
    json = JSON response.body
    json.should include('errors')
    errors = json['errors']
    errors.should have(2).errors
    errors[0].should == 'Transfer failed. Please try again in a few seconds.'
    errors[1].should == 'a failure message'
  end
end
