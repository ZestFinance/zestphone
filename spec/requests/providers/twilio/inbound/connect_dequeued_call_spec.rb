require 'spec_helper'

describe 'Connecting a dequeued call' do
  context 'given a non-whitelisted phone number' do
    before do
      Telephony::Call.any_instance.stub(:whitelisted_number?).and_return false
      call = create :call
      agent = create :agent
      create :connecting_agent_leg, conversation: call.conversation, agent: agent

      post "/zestphone/providers/twilio/inbound_calls/connect?csr_id=#{agent.csr_id}",
        CallSid: call.sid
    end

    it 'returns TwiML saying the number is not whitelisted' do
      xml = Nokogiri::XML response.body
      say = xml.at '/Response/Say'
      say.text.should =~ /the number you are trying to call is not whitelisted/i
    end
  end

  context 'given a whitelisted phone number' do
    before do
      Telephony.stub(:whitelisted?).and_return true
      @conversation = create :conversation
      customer_leg = create :call, conversation: @conversation
      @agent = create :agent, phone_number: '222-333-4444'
      create :connecting_agent_leg, conversation: @conversation, agent: @agent

      post "/zestphone/providers/twilio/inbound_calls/connect?csr_id=#{@agent.csr_id}",
        CallSid: customer_leg.sid
    end

    it 'creates an agent leg for the conversation' do
      @conversation.reload
      @conversation.should have(2).calls
      agent_leg = @conversation.calls.last
      agent_leg.agent.should == @agent
    end

    it 'connects the agent leg' do
      @conversation.reload
      agent_leg = @conversation.calls.last
      agent_leg.should be_connecting
    end

    it 'returns TwiML for dialing the phone number' do
      @conversation.reload
      customer = @conversation.customer
      agent_leg = @conversation.active_agent_leg

      xml = Nokogiri::XML response.body

      dial = xml.at '/Response/Dial'
      dial.attributes['record'].value.should == "true"
      dial.attributes['action'].value.should == "/zestphone/providers/twilio/calls/#{customer.id}/child_detached"

      number = dial.at 'Number'
      number.text.should == @agent.phone_number
      number.attributes['url'].value.should == "/zestphone/providers/twilio/calls/#{agent_leg.id}/child_answered"
    end
  end

  context 'given a twilio client number' do
    before do
      @conversation = create :conversation, caller_id: 'caller_id'
      customer_leg = create :call, conversation: @conversation
      @agent = create :agent, phone_type: Telephony::Agent::PhoneType::TWILIO_CLIENT
      create :connecting_agent_leg, conversation: @conversation, agent: @agent

      post "/zestphone/providers/twilio/inbound_calls/connect?csr_id=#{@agent.csr_id}",
        CallSid: customer_leg.sid
    end

    it "returns TwiML for dialing the agent's twilio client" do
      @conversation.reload
      customer = @conversation.customer
      agent_leg = @conversation.active_agent_leg

      xml = Nokogiri::XML response.body

      dial = xml.at '/Response/Dial'
      dial.attributes['record'].value.should == "true"
      dial.attributes['callerId'].value.should == "caller_id"
      dial.attributes['action'].value.should == "/zestphone/providers/twilio/calls/#{customer.id}/child_detached"

      client = dial.at 'Client'
      client.text.should == "agent#{@agent.csr_id}"
      client.attributes['url'].value.should == "/zestphone/providers/twilio/calls/#{agent_leg.id}/child_answered"
    end
  end

  context 'given a sip number' do
    before do
      @conversation = create :conversation, caller_id: 'caller_id'
      customer_leg = create :call, conversation: @conversation
      @agent = create :agent,
        phone_type: Telephony::Agent::PhoneType::SIP,
        sip_number: '200',
        call_center_name: 'other_location'
      create :connecting_agent_leg, conversation: @conversation, agent: @agent

      post "/zestphone/providers/twilio/inbound_calls/connect?csr_id=#{@agent.csr_id}",
        CallSid: customer_leg.sid
    end

    it "returns TwiML for dialing the agent's sip address" do
      @conversation.reload
      customer = @conversation.customer
      agent_leg = @conversation.active_agent_leg

      xml = Nokogiri::XML response.body

      dial = xml.at '/Response/Dial'
      dial.attributes['record'].value.should == "true"
      dial.attributes['callerId'].value.should == "caller_id"
      dial.attributes['action'].value.should == "/zestphone/providers/twilio/calls/#{customer.id}/child_detached"

      client = dial.at 'Sip'
      client.text.should == "200@192.168.1.2"
      client.attributes['url'].value.should == "/zestphone/providers/twilio/calls/#{agent_leg.id}/child_answered"
    end
  end
end
