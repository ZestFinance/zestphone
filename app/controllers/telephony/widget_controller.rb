require_dependency "telephony/application_controller"

module Telephony
  class WidgetController < ApplicationController

    def index
      render layout: false, content_type: 'application/json'
    end
  end
end
