require 'state_machine'
require 'kaminari'

module Telephony
  class Engine < ::Rails::Engine
    isolate_namespace Telephony

    config.autoload_paths += Dir["#{config.root}/lib"]

    config.generators do |generators|
      generators.test_framework :rspec, view_specs:  false
    end

    config.active_record.observers = 'Telephony::CallObserver',
      'Telephony::AgentObserver',
      'Telephony::EventObserver',
      'Telephony::ConversationObserver'
  end
end
