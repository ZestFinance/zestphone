module Telephony
  module NumberHelper
    def normalize_number(number)
      number.gsub(/\D/, '').gsub(/^1/, '')
    end

    def extract_area_code(number)
      normalize_number(number)[0..2]
    end
  end
end
