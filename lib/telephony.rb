require 'telephony/engine'
require 'telephony/helper'
require 'telephony/providers/twilio_provider'

module Telephony
  mattr_accessor :provider, :whitelist, :pop_url_finder

  def self.whitelisted? number
    ! whitelist || begin
      normalize = -> number do
        number
          .gsub(/\D/, '')
          .last(10)
      end
      normalized_number = normalize[number]
      whitelist.any? do |whitelisted_number|
        normalize[whitelisted_number] == normalized_number
      end
    end
  end

  def self.with_whitelisting number
    if whitelisted? number
      number
    else
      provider.uncallable_number
    end
  end
end
