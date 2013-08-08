require_dependency 'telephony/application_controller'

module Telephony
  class ConversationsController < ApplicationController

    def index
      conversations = ConversationData.filter params
      render json: conversations
    end

    def counts
      counts = ConversationData.counts params
      render json: counts
    end

    def search
      conversations = ConversationData.search params
      conversations_presenter = ConversationsPresenter.new conversations
      render json: {
        total_count: conversations.total_count,
        conversations: conversations_presenter
      }
    end

    def create
      conversation = Conversation.begin! params

      render json: {
        id:     conversation.id,
        number: conversation.customer.number
      }
    rescue Telephony::Error::Connection => e
      msg = 'Call failed. Please try again in a few seconds.'
      Rails.logger.error "#{msg} - #{e.message} - #{params}"
      errors = [msg, e.message]

      render json: { errors: errors }, status: :server_error
    end

    def update
      Conversation.find_with_lock params[:id] do |conversation|
        conversation.update_attributes loan_id: params[:loan_id]
        render json: conversation
      end
    end

    def hold
      lock_conversation(params['id'], 'Hold failed. Please try again in a few seconds.') do |conversation|
        conversation.hold!
        render json: {}
      end
    end

    def resume
      lock_conversation(params['id'], 'Resume failed. Please try again in a few seconds.') do |conversation|
        conversation.resume!
        render json: {}
      end
    end

    private

    def lock_conversation(conversation_id, msg)
      Conversation.find_with_lock(conversation_id) do |conversation|
        yield conversation
      end
    rescue Telephony::Error::Connection, Telephony::Error::NotInProgress, StateMachine::InvalidTransition => e
      Rails.logger.error "#{msg} - #{e.message} - #{params}"
      errors = [msg, e.message]

      render json: { errors: errors }, status: :server_error
    end
  end
end
