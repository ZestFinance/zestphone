module Telephony
  module Providers
    class TwilioProvider
      include Telephony::NumberHelper

      RING_TIMEOUT_IN_SECONDS = 60
      RING_TRANSFER_TIMEOUT_IN_SECONDS = 15
      REQUEST_TIMEOUT_IN_SECONDS = 6

      attr_accessor :account_sid,
        :auth_token,
        :outbound_caller_id,
        :callback_root,
        :voice_url,
        :sms_application_sid,
        :twilio_provider_url

      def initialize(config)
        config.to_options!
        self.account_sid = config[:account_sid]
        self.auth_token = config[:auth_token]
        self.outbound_caller_id = config[:outbound_caller_id]
        self.callback_root = config[:callback_root]
        self.voice_url = config[:voice_url]
        self.sms_application_sid = config[:sms_application_sid]
        self.twilio_provider_url = "#{callback_root}/providers/twilio/calls"
        @incoming_phone_numbers_cache = {}
      end

      def call(call_id, destination, caller_id)
        create_call number: destination,
          caller_id: caller_id,
          callback_url: "#{twilio_provider_url}/#{call_id}/connect",
          call_id: call_id,
          timeout: RING_TIMEOUT_IN_SECONDS
      end

      def redirect_to_dial(call_id, sid)
        redirect_or_raise sid, "#{twilio_provider_url}/#{call_id}/dial"
      end

      def redirect_to_inbound_connect(csr_id, sid)
        redirect_or_raise sid, "#{callback_root}/providers/twilio/inbound_calls/connect?csr_id=#{csr_id}"
      end

      def redirect_to_conference(call_id, sid)
        redirect_or_raise sid, "#{twilio_provider_url}/#{call_id}/join_conference"
      end

      def redirect_to_hold(call_id, sid)
        redirect_or_raise sid, "#{twilio_provider_url}/#{call_id}/complete_hold"
      end

      def dial_into_conference(call_id, destination, caller_id)
        create_call number: destination,
          caller_id: caller_id,
          callback_url:  "#{twilio_provider_url}/#{call_id}/join_conference",
          call_id: call_id,
          timeout: RING_TRANSFER_TIMEOUT_IN_SECONDS
      end

      def hangup(sid)
        call = client.account.calls.find sid
        call.hangup
      rescue => error
        log_error(error, "Error during hangup for call sid: '#{sid}'")
        false
      end

      def caller_id_for(area_code)
        incoming_phone_number_from_cache(area_code) ||
            fetch_existing_incoming_phone_numbers(area_code) ||
            buy_number_for_area_code(area_code) ||
            normalize_number(outbound_caller_id)
      end

      def buy_number_for_area_code(area_code)
        number = buy_number(area_code)
        @incoming_phone_numbers_cache[area_code] = number
        number
      rescue Exception => error
        Rails.logger.info "Failed attempt to buy a phone number in area code '#{area_code}': #{error.message}"
        nil
      end

      def uncallable_number
        'this-number-is-not-whitelisted'
      end

      def call_ended?(sid)
        call = client.account.calls.find sid
        call.status.in?(%w(completed failed busy no-answer))
      rescue ::Twilio::REST::RequestError, NoMethodError
        false
      rescue => error
        log_error(error, "Error when verifying if call ended")
        false
      end

      def client
        @client ||= ::Twilio::REST::Client.new account_sid, auth_token, timeout: REQUEST_TIMEOUT_IN_SECONDS
      end

      private

      def incoming_phone_number_from_cache(area_code)
        @incoming_phone_numbers_cache[area_code]
      end

      def fetch_existing_incoming_phone_numbers(area_code)
        raise_on_error('Failed to fetch incoming phone numbers') do
          numbers = client.account.incoming_phone_numbers.list(phone_number: "+1#{area_code}*******")
          numbers.each do |num|
            @incoming_phone_numbers_cache[extract_area_code(num.phone_number)] = normalize_number(num.phone_number)
          end
          @incoming_phone_numbers_cache[area_code]
        end
      end

      def buy_number(area_code)
        response = client.account.incoming_phone_numbers.create area_code: area_code,
            voice_url: voice_url,
            sms_application_sid: sms_application_sid
        normalize_number(response.phone_number)
      end

      def create_call(args)
        raise_on_error('Failed to create a call') do
          client.account.calls.create(from: args[:caller_id],
                                      to: args[:number],
                                      url: args[:callback_url],
                                      status_callback: "#{twilio_provider_url}/#{args[:call_id]}/done",
                                      timeout: args[:timeout])
        end
      end

      def redirect_or_raise(sid, to)
        raise_on_error("Failed to redirect #{sid} to #{to}") do
          call = client.account.calls.find sid
          call.redirect_to to
          true
        end
      end

      def raise_on_error(msg = 'Error')
        begin
          yield
        rescue => error
          log_error(error, msg)
          if error.respond_to?(:code) && error.code == 21220
            raise Telephony::Error::NotInProgress.new("#{msg} - #{error.message}")
          else
            raise Telephony::Error::Connection.new("#{msg} - #{error.message}")
          end
        end
      end

      def log_error(error, msg)
        Rails.logger.error "Twilio provider - #{msg} - #{error.class} - #{error.message}"
      end
    end
  end
end
