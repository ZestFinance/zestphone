module Telephony
  class CallObserver < ActiveRecord::Observer
    def after_save(call)
      return unless call.agent_id

      Agent.find_with_lock(call.agent_id) do |agent|
        if call.terminated? && call.state_was != 'not_initiated' && call.state_was != 'terminated'
          agent.call_ended
        elsif call.connecting?
          agent.on_a_call
        end
      end
    end
  end
end
