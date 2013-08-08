require_dependency 'telephony/application_controller'

module Telephony
  class AgentsController < ApplicationController
    def show_by_csr_id
      agent = Agent.find_by_csr_id params[:csr_id]
      render json: agent.as_json(only: [:id, :csr_id, :name], methods: :active_conversation_id)
    end

    def update
      agent = Agent.update_or_create_by_widget_data params

      if agent.valid?
        render status: :ok, json: { conversation_id: agent.active_conversation_id }
      else
        render status: :bad_request, json: { errors: agent.errors.full_messages }
      end
    end

    def status
      agent = Agent.find_by_csr_id params[:id]
      agent.fire_events params[:event]

      render :json => { :csr_id => agent.csr_id, :status => agent.status }
    end

    def index
      agents = Agent.all_transferable_for_csr_id params[:csr_id]

      render :json => agents
    end
  end
end
