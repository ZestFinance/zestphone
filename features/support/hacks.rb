########################################################
# HACK: Ignore intermittent StaleElementReferenceError #
########################################################
require 'timeout'

module Telephony
  module Capybara
    module Hacks
      def wait_until_ignoring_errors seconds = 10
        Timeout::timeout seconds do
          loop do
            begin
              yield
              break true
            rescue Selenium::WebDriver::Error::StaleElementReferenceError
              retry
            end
          end
        end
      end
    end
  end
end

World(Telephony::Capybara::Hacks)
