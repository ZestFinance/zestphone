module Telephony
  module Inbound
    class ConversationQueuesController < ApplicationController
      def front
        @inbound_conversation = InboundConversationQueue.dequeue params[:csr_id]
        render json: @inbound_conversation

      rescue Telephony::Error::QueueEmpty
        render status: :not_found, json: { errors: [ "Queue is empty" ] }

      rescue Telephony::Error::AgentOnACall
        render status: :unprocessable_entity, json: { errors: [ "You are already on a call" ] }

      rescue => error
        msg = "Error dequeueing call: #{error.message}"
        Rails.logger.error msg
        render status: :server_error, json: { errors: [ msg ] }
      end
    end
  end
end
