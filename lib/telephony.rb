require 'telephony/engine'
require 'telephony/helper'
require 'telephony/providers/twilio_provider'

module Telephony
  mattr_accessor :provider,
                 :whitelist,
                 :pop_url_finder,
                 :hold_music,
                 :wait_music

  def self.whitelisted? number
    ! whitelist || begin
      normalized_number = americanize number
      whitelist.any? do |whitelisted_number|
        americanize(whitelisted_number) == normalized_number
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

  def self.americanize number
    number
      .gsub(/\D/, '')
      .last(10)
  end
end
