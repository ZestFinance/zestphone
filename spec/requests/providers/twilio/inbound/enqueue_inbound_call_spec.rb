require 'spec_helper'

module Telephony
  describe 'Receive an inbound call', :vcr do
    before do
      @from = '555-555-1234'
      @to = '555-555-1235'
    end

    context "offices are open" do
      before do
        Telephony::OFFICE_HOURS.stub(:open?).and_return true
        @count = Conversation.count
        post '/zestphone/providers/twilio/inbound_calls', From: @from, To: @to
      end

      it 'plays the open hours greeting' do
        xml = Nokogiri::XML response.body
        play = xml.at('/Response/Play')
        play.text.should =~ /monkey\.mp3$/
      end

      it 'creates a new conversation' do
        Conversation.count.should == @count + 1
      end
    end

    context "offices are closed" do
      before do
        Telephony::OFFICE_HOURS.stub(:open?).and_return false
        post '/zestphone/providers/twilio/inbound_calls', From: @from, To: @to
      end

      it "plays the closed hours greeting" do
        xml = Nokogiri::XML response.body
        play = xml.at('/Response/Play')
        play.text.should =~ /cowbell\.mp3$/
      end
    end

    context "number is on the reject list" do
      before do
        Telephony::BlacklistedNumber.create number: Telephony.americanize(@from)
        post '/zestphone/providers/twilio/inbound_calls', From: @from, To: @to
      end

      it "rejects the call" do
        xml = Nokogiri::XML response.body
        reject = xml.at('/Response/Reject')
        reject.should be_present
      end
    end
  end

  describe 'Enqueue an inbound call', :vcr do
    context 'when a customer hangs up while listening our greetings message' do
      before do
        @call = create :call
        @call.conversation.play_message
        post "/zestphone/providers/twilio/inbound_calls/#{@call.conversation_id}/enqueue",
          CallStatus: 'completed'
      end

      it 'terminates the call' do
        @call.reload.should be_terminated
      end

      it 'renders a whisper tone' do
        xml = Nokogiri::XML response.body
        xml.at('/Response').text.should be_empty
      end
    end

    context 'when a customer stays on the line' do
      before do
        @call = create :call
        @call.conversation.play_message
        post "/zestphone/providers/twilio/inbound_calls/#{@call.conversation_id}/enqueue",
          CallStatus: 'in-progress'
      end

      it 'enqueues the conversation' do
        @call.conversation.reload.should be_enqueued
      end

      it 'renders the enqueue template' do
        xml = Nokogiri::XML response.body
        enqueue = xml.at('/Response/Enqueue')
        enqueue.text.should == 'inbound'
        enqueue.attributes['action'].value
          .should == "/zestphone/providers/twilio/calls/#{@call.id}/leave_queue"
      end
    end

    context 'when a customer gets the wait music' do
      before do
        get "/zestphone/providers/twilio/inbound_calls/wait_music"
      end

      it 'should play the correct file' do
        xml = Nokogiri::XML response.body
        play = xml.at('/Response/Play')
        play.text.should == 'https://example.com/wait_music.wav'
        play.attributes['loop'].value.should == '0'
      end
    end
  end
end
