module Telephony
  module Steps
    module Helper
      def twilio_rest_client
        @twilio_rest_client ||= ::Twilio::REST::Client.new TWILIO_CONFIG[:account_sid],
          TWILIO_CONFIG[:auth_token]
      end
    end
  end
end

World(Telephony::Steps::Helper)
