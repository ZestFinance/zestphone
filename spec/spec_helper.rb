# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rspec/rails"
require "timecop"
require "webmock/rspec"

ENGINE_RAILS_ROOT=File.join(File.dirname(__FILE__),'../')

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.color_enabled = true
  config.render_views
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.extend VCR::RSpec::Macros

  config.include PusherSignatureHelper, :type => :controller

  config.before do
    ActiveRecord::Base.observers.disable :all
  end
end
