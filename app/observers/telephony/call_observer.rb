module Telephony
  class CallObserver < ActiveRecord::Observer
    def after_save(call)
      return unless call.agent

      if call.terminated? && call.state_was != 'not_initiated'
        call.agent.not_available
      elsif call.connecting?
        call.agent.on_a_call
      end
    end
  end
end
