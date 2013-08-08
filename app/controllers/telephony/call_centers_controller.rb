require_dependency 'telephony/application_controller'

module Telephony
  class CallCentersController < ApplicationController
    def index
      render json: CallCenter.all
    end
  end
end
