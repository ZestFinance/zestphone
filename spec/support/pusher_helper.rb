require 'openssl'

module PusherSignatureHelper
  def sign_pusher_request(payload)
    secret = PUSHER_CONFIG["secret"]
    digest = OpenSSL::Digest::SHA256.new
    body = payload.to_query
    signature = OpenSSL::HMAC.hexdigest(digest, secret, body)
    request.env['HTTP_X_PUSHER_SIGNATURE'] = signature

    request.env['HTTP_X_PUSHER_KEY'] = PUSHER_CONFIG["app_key"]
  end
end
