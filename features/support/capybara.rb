require 'capybara/cucumber'
Capybara.default_wait_time = 5

# Usage:
#   BROWSER=chrome bundle exec cucumber
if ENV['BROWSER']
  require 'selenium/webdriver'
  browser = ENV['BROWSER'].to_sym

  Capybara.register_driver :selenium_with_custom_browser do |app|
    Capybara::Selenium::Driver.new(app,
      :browser => browser
    )
  end
  Capybara.javascript_driver = :selenium_with_custom_browser
end
