require 'spec_helper'

describe 'Creating a conversation' do
  let(:twilio_provider) { double('twilio_provider', client: twilio_client) }
  let(:twilio_client) { double('twilio_client', account: twilio_account) }
  let(:twilio_call1) { double('twilio_call1') }
  let(:twilio_calls) { double('twilio_calls', find: twilio_call1) }
  let(:twilio_account) { double('twilio_account', calls: twilio_calls) }

  let(:agent) {  create :agent, csr_type: 'B' }

  let(:dial_call_sid) { 'i am the dial call sid' }
  let(:agent_call_sid1) { 'i, however, am the agent call sid' }
  let(:agent_call_sid2) { 'i, by contract, am the second agent call sid' }

  let(:twilio_call)

  before do
    Telephony.provider.stub(:client).and_return(twilio_client)

    twilio_call1.should_receive(:redirect_to).twice do |params|
      @call_redirect_params = params
    end
  end

  let(:attributes) do
    {
      from:      '310-456-7890',
      to:        '310-765-4321',
      loan_id:   1
    }
  end

  it "should not reuse the old call on the second pick up" do
    post "/zestphone/providers/twilio/inbound_calls",
        From: attributes[:from], CallSid: dial_call_sid, To: attributes[:to]

    response.should be_success
    xml = Nokogiri::XML(response.body)
    enqueue_call_callback =  xml.xpath("//Redirect").text

    post enqueue_call_callback, CallStatus: "in-progress"

    response.should be_success
    xml = Nokogiri::XML(response.body)
    leave_queue_callback =  xml.xpath("//Enqueue/@action").text

    xhr :delete, '/zestphone/inbound/front', csr_id: agent.csr_id
    @call_redirect_params.should_not be_empty

    post leave_queue_callback, QueueResult: 'redirected'
    response.should be_success

    post @call_redirect_params, CallSid: dial_call_sid

    response.should be_success
    xml = Nokogiri::XML(response.body)
    redirect_failed_callback = xml.xpath("//Dial/@action").text
    answer_callback1 = xml.xpath("//Dial/Number/@url").text

    post redirect_failed_callback,
        CallSid: dial_call_sid,
        DialCallSid: agent_call_sid1,
        DialCallStatus: 'no-answer',
        CallStatus: 'in-progress'

    response.should be_success
    xml = Nokogiri::XML(response.body)
    leave_queue_callback =  xml.xpath("//Enqueue/@action").text

    xhr :delete, '/zestphone/inbound/front', csr_id: agent.csr_id
    @call_redirect_params.should_not be_empty

    post leave_queue_callback, QueueResult: 'redirected'
    response.should be_success

    post @call_redirect_params, CallSid: dial_call_sid


    response.should be_success
    xml = Nokogiri::XML(response.body)
    redirect_failed_callback = xml.xpath("//Dial/@action").text
    answer_callback2 = xml.xpath("//Dial/Number/@url").text

    answer_callback2.should_not == answer_callback1

    # post answer_callback2, CallSid: agent_call_sid2
  end
end
