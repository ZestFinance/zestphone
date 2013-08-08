module Telephony
  class Base < ActiveRecord::Base
    establish_connection "telephony_#{Rails.env}"

    self.abstract_class = true
  end
end
