module Telephony
  module Providers
    module Twilio
      class ApplicationController < Telephony::ApplicationController
        include Telephony::Concerns::Controllers::TwilioRequestVerifier

        private

        def render_complete_hold
          @call.complete_hold!
          render 'telephony/providers/twilio/calls/complete_hold'
        end

        def render_conference
          @call.conference!
          render 'telephony/providers/twilio/calls/join_conference'
        end

        def child_hung_up?
          params[:DialCallStatus] == 'completed' &&
            params[:DialCallDuration].present?
        end
      end
    end
  end
end
