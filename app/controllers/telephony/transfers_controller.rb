require_dependency 'telephony/application_controller'

module Telephony
  class TransfersController < ApplicationController
    def create
      Conversation.find_with_lock params[:conversation_id] do |conversation|
        if conversation.transfer! params[:transfer_id], params[:transfer_type] == 'one_step'
          render json: {}
        else
          errors = ['Transfer failed. Please try again in a few seconds.'] +
            conversation.errors.full_messages

          render json: { errors: errors }, status: :unprocessable_entity
        end
      end
    end
  end
end
