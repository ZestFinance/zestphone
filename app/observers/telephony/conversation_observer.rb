module Telephony
  class ConversationObserver < ActiveRecord::Observer
    def after_save(conversation)
      return unless conversation.state_was == 'enqueued' || conversation.enqueued?

      PusherEventPublisher.queue_change Conversation.queue_size, Events::Base.select(:id).last.id
    end
  end
end
