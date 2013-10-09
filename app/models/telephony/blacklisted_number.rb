module Telephony
  class BlacklistedNumber < ActiveRecord::Base
    attr_accessible :number
  end
end
