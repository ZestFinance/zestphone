module Telephony
  module Signals
    module Agents
      class PresencesController < ApplicationController
        protect_from_forgery :except => [:authenticate, :create]
        before_filter :verify_pusher_request_signature, :except => :authenticate
        after_filter :publish_events

        def authenticate
          @agent = Agent.find_by_csr_id params[:csr_id]

          @agent.verify_status!

          @agent.with_lock do
            if @agent.offline?
              if params[:csr_default_status] == 'not_available'
                @agent.not_available
              else
                @agent.available
              end
            end
          end

          response = Pusher[params[:channel_name]]
            .authenticate(params[:socket_id], user_id: @agent.id)
          render json: response
        end

        def create
          timestamp = params["presence"]["time_ms"].to_i
          params[:presence][:events].each do |data|
            @agent = Agent.where(id: data[:user_id]).first
            if @agent
              @agent.with_lock do
                @agent.process_presence_event(data[:name], timestamp)
              end
            end
          end
          head :ok
        end

        private

        def verify_pusher_request_signature
          req = Pusher::WebHook.new request
          unless req.valid?
            render :text => "Bad Pusher signature", :status => :unauthorized and return
          end
        end

        def publish_events
          return if @agent.nil?

          event = Events::Base.find_last_for_agent(@agent)
          event.republish_only_for @agent

          @agent.publish_status_change unless @agent.offline?

          PusherEventPublisher.queue_change Conversation.queue_size, event.id, @agent
        end
      end
    end
  end
end
