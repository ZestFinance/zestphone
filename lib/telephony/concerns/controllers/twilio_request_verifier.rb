module Telephony::Concerns::Controllers::TwilioRequestVerifier
  extend ActiveSupport::Concern

  included do
    before_filter :verify_twilio_request, if: :use_twilio_digest_auth?
  end

  def verify_twilio_request
    unless twilio_request_validated?
      render :text => "Twilio request signature verification failed.", :status => :unauthorized
    end
  end

  def twilio_request_validated?
    validator = Twilio::Util::RequestValidator.new(twilio_config[:auth_token])
    # Only use the POST parameters, not the url params or the rails-added params
    twilio_params = request.request_parameters
    signature = request.headers['HTTP_X_TWILIO_SIGNATURE']

    validator.validate(callback_url, twilio_params, signature)
  end

  private

  def callback_url
    domain = twilio_config[:callback_domain]
    protocol = twilio_config[:behind_https_proxy] ? "https://" : "http://"

    "#{protocol}#{domain}#{request.fullpath}"
  end

  def twilio_config
    TWILIO_CONFIG
  end

  def use_twilio_digest_auth?
    twilio_config[:use_twilio_digest_auth]
  end
end
