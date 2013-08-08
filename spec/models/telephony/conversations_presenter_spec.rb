require 'spec_helper'

module Telephony
  describe ConversationsPresenter do
    describe '#as_json' do
      before do
        @conversations = 2.times.map do
          conversation = create :conversation
          calls = create_list :call, 2, conversation: conversation
          calls.each do |call|
            create :recording, call: call
          end
          conversation
        end
        conversations_presenter = ConversationsPresenter.new @conversations

        @as_json = conversations_presenter.as_json
      end

      it 'includes each of its conversations' do
        @as_json.should have(@conversations.size).conversations
      end

      it 'includes the calls for each of its conversations' do
        @as_json.each do |conversation|
          conversation[:calls].should have(2).calls
        end
      end

      it 'includes the recordings for each of its calls for each of its conversations' do
        @as_json.each do |conversation|
          calls = conversation[:calls]
          calls.each do |call|
            call[:recordings].should have(1).recording
          end
        end
      end
    end
  end
end
