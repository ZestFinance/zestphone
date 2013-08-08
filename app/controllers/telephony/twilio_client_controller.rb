require_dependency "telephony/application_controller"

module Telephony
  class TwilioClientController < ApplicationController
    before_filter :validate_params, only: :token

    def index
      @token = generate_token_for("agent#{params['csr-id']}")
      render layout: false
    end

    def token
      token = generate_token_for("agent#{params['csr_id']}")
      render json: { token: token }
    end

    private

    def validate_params
      if params['csr_id'].blank?
        render json: { errors: ['Invalid csr id'] },
          status: :bad_request
      end
    end

    def generate_token_for client_name
      account_sid = TWILIO_CONFIG[:account_sid]
      auth_token = TWILIO_CONFIG[:auth_token]

      capability = Twilio::Util::Capability.new account_sid, auth_token
      # TODO: Get the correct value
      capability.allow_client_outgoing "APabe7650f654fc34655fc81ae71caa3ff"
      capability.allow_client_incoming client_name
      capability.generate
    end
  end
end
