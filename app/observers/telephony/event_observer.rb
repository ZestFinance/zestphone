module Telephony
  class EventObserver < ActiveRecord::Observer
    observe Telephony::Events::Base

    def after_create(event)
      event.publish
    end
  end
end
