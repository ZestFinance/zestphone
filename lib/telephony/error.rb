module Telephony
  module Error
  end
end

require_relative 'error/base'
require_relative 'error/not_in_progress'
require_relative 'error/queue_empty'
