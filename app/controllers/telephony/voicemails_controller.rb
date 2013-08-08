require_dependency 'telephony/application_controller'

module Telephony
  class VoicemailsController < ApplicationController
    def index
      @voicemails = Voicemail.most_recent.filter params.slice(:page, :csr_id)
      render json: {
        items: @voicemails,
        total_count: @voicemails.total_count
      }
    end
  end
end
