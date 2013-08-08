require_dependency 'telephony/providers/twilio/application_controller'

module Telephony
  module Providers
    module Twilio
      class VoicemailsController < ApplicationController
        around_filter :lock_conversation

        def create
          @call.create_voicemail csr_id: params[:csr_id],
            url: params[:RecordingUrl],
            duration: params[:RecordingDuration]
          @call.terminate

          render 'telephony/providers/twilio/calls/whisper_tone'
        end

        private

        def lock_conversation
          @call = Call.find params[:call_id]
          Conversation.find_with_lock(@call.conversation_id) do
            yield
          end
        end
      end
    end
  end
end
