require_dependency "telephony/application_controller"

module Telephony
  class PlayableListenersController < ApplicationController
    before_filter :sanitize_params
    before_filter :validate_csr, only: :create
    before_filter :validate_playable, only: [:index, :create]

    def index
      listeners = PlayableListener.filter params

      render json: listeners
    end

    def recent
      listeners = PlayableListener.recent params

      render json: listeners
    end

    def create
      listener = PlayableListener.register params

      render status: :created, json: listener
    end

    private

    def sanitize_params
      params[:playable_ids] = Array(params[:playable_ids]) if params[:playable_ids]
      params[:per] = 5 if params[:per].blank?
      params.slice! :csr_id, :playable_id, :playable_ids, :page, :per
    end

    def validate_playable
      head :bad_request if params[:playable_id].blank?
    end

    def validate_csr
      head :bad_request if params[:csr_id].blank?
    end
  end
end
