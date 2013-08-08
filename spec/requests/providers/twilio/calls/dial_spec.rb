require 'spec_helper'

describe 'Dialing a whitelisted number' do
  before do
    @to = '8881234567'
    @conversation = create :initiating_one_step_transferring_conversation
    @call = @conversation.initiating_call
    @child_call = @conversation.not_initiated_call

    @existing_whitelist = Telephony.whitelist
    Telephony.whitelist = [@to]
  end

  after do
    Telephony.whitelist = @existing_whitelist
  end

  context 'when one-step transferring to an available agent' do
    context "with a phone number" do
      before do
        agent = create :available_agent, phone_number: @to
        @child_call.update_attributes agent: agent, number: @to

        post "/zestphone/providers/twilio/calls/#{@call.id}/dial"
      end

      it 'returns TwiML for dialing to a specific number' do
        xml = Nokogiri::XML response.body
        dial = xml.at('/Response/Dial')
        dial.attributes['method'].value.should == 'POST'
        dial.attributes['action'].value.should == "/zestphone/providers/twilio/calls/#{@call.id}/child_detached"
        dial.attributes['record'].value.should == 'true'
        dial.attributes['timeout'].value.should == '15'
        number = dial.at('Number')
        number.attributes['url'].value.should == "/zestphone/providers/twilio/calls/#{@child_call.id}/child_answered"
        number.text.should == @to
      end
    end

    context "with a twilio client" do
      before do
        @agent = create :available_agent,
          phone_type: Telephony::Agent::PhoneType::TWILIO_CLIENT
        @child_call.update_attributes agent: @agent

        post "/zestphone/providers/twilio/calls/#{@call.id}/dial"
      end

      it "returns TwiML for dialing to the agent's twilio client" do
        xml = Nokogiri::XML response.body
        dial = xml.at('/Response/Dial')
        dial.attributes['method'].value.should == 'POST'
        dial.attributes['action'].value.should == "/zestphone/providers/twilio/calls/#{@call.id}/child_detached"
        dial.attributes['record'].value.should == 'true'
        dial.attributes['timeout'].value.should == '15'
        client = dial.at('Client')
        client.attributes['url'].value.should == "/zestphone/providers/twilio/calls/#{@child_call.id}/child_answered"
        client.text.should == "agent#{@agent.csr_id}"
      end
    end

    context "with a sip" do
      before do
        @agent = create :available_agent,
          phone_type: Telephony::Agent::PhoneType::SIP,
          sip_number: 200,
          call_center_name: 'other_location'
        @child_call.update_attributes agent: @agent

        post "/zestphone/providers/twilio/calls/#{@call.id}/dial"
      end

      it "returns TwiML for dialing to the agent's sip number" do
        xml = Nokogiri::XML response.body
        dial = xml.at('/Response/Dial')
        dial.attributes['method'].value.should == 'POST'
        dial.attributes['action'].value.should == "/zestphone/providers/twilio/calls/#{@call.id}/child_detached"
        dial.attributes['record'].value.should == 'true'
        dial.attributes['timeout'].value.should == '15'
        client = dial.at('Sip')
        client.attributes['url'].value.should == "/zestphone/providers/twilio/calls/#{@child_call.id}/child_answered"
        client.text.should == "200@192.168.1.2"
      end
    end
  end

  context 'when leaving a voicemail for an unavailable agent' do
    before do
      @conversation.leave_voicemail!
      @agent = create :not_available_agent, phone_number: @to
      @child_call.update_attributes agent: @agent, number: @to

      post "/zestphone/providers/twilio/calls/#{@call.id}/dial"
    end

    it 'returns TwiML for leaving a voicemail' do
      xml = Nokogiri::XML response.body
      say = xml.at '/Response/Say'
      say.text.should =~ /at extension #{@agent.phone_ext}/i
      say.text.should =~ /record your message/i
      record = xml.at '/Response/Record'
      record.attributes['action'].value.should == "/zestphone/providers/twilio/calls/#{@call.id}/voicemail?csr_id=#{@agent.csr_id}"
    end
  end
end

describe 'Dialing a non-whitelisted number' do
  context "one step transferring to an agent" do
    before do
      @to = '8881234567'
      @conversation = create :initiating_one_step_transferring_conversation
      @call = @conversation.initiating_call
      @child_call = @conversation.not_initiated_call
      available_agent = create :available_agent, phone_number: @to
      @child_call.update_attributes agent: available_agent
      @existing_whitelist = Telephony.whitelist
      Telephony.whitelist = []

      post "/zestphone/providers/twilio/calls/#{@call.id}/dial"
    end

    after do
      Telephony.whitelist = @existing_whitelist
    end

    it 'dials the number since we trust our agents' do
      xml = Nokogiri::XML response.body
      number = xml.at('/Response/Dial/Number')
      number.text.should == @to
    end
  end
end
