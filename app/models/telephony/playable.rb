module Telephony
  class Playable < Base
    attr_accessible :start_time, :url, :duration

    belongs_to :call
  end
end
