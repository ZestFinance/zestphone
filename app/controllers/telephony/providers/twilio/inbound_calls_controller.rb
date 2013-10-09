module Telephony
  module Providers
    module Twilio
      class InboundCallsController < ApplicationController
        def create
          if Telephony::BlacklistedNumber.where(number: Telephony.americanize(params[:From])).exists?
            InboundConversationQueue.reject params
            render :reject
          else
            play_message
          end
        end

        def wait_music
        end

        def enqueue
          Conversation.find_inbound_with_lock(params[:id]) do |conversation|
            @call = conversation.calls.first

            if params[:CallStatus] == 'completed'
              @call.terminate!
              render template: 'telephony/providers/twilio/calls/whisper_tone'
            else
              conversation.enqueue!
            end
          end
        end

        def connect
          @call = Call.find_by_sid params[:CallSid]
          agent = Agent.find_by_csr_id params[:csr_id]
          @connecting_call = @call.conversation.calls.find_by_agent_id agent.id

          render template: '/telephony/providers/twilio/calls/connect'
        end

        private

        def play_message
          if Telephony::OFFICE_HOURS.open?
            @conversation = InboundConversationQueue.play_message params
            @files = Telephony::OFFICE_HOURS.open_hours_audio_files params
            render :create
          else
            InboundConversationQueue.play_closed_greeting params
            @files = Telephony::OFFICE_HOURS.closed_hours_audio_files params
            render :closed_hours
          end
        end
      end
    end
  end
end
