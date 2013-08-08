module Telephony
  module CallsHelper
    def twiml_word_for call
      if call.agent && call.agent.uses_twilio_client?
        :Client
      elsif call.agent && call.agent.uses_sip?
        :Sip
      else
        :Number
      end
    end
  end
end
