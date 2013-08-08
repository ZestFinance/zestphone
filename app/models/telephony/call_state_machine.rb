require 'state_machine'

module Telephony
  module CallStateMachine
    extend ActiveSupport::Concern

    included do
      state_machine :state, :initial => :not_initiated do
        event :connect do
          transition not_initiated: :connecting
        end

        event :no_answer do
          transition connecting: :terminated
        end

        event :busy do
          transition connecting: :terminated
        end

        event :call_fail do
          transition connecting: :terminated
        end

        event :answer do
          transition connecting: :in_progress
        end

        event :conference do
          transition connecting:       :in_conference,
                     in_progress:      :in_conference,
                     in_progress_hold: :in_conference,
                     in_conference:    :in_conference
        end

        event :dial_agent do
          transition in_conference:    :in_progress,
                     in_progress:      :in_progress,
                     in_progress_hold: :in_progress
        end

        event :straight_to_voicemail do
          transition :not_initiated => :terminated
        end

        event :terminate do
          transition all - [:terminated] => :terminated
        end

        event :complete_hold do
          transition [:in_progress, :in_conference] => :in_progress_hold
        end

        before_transition :on => :answer do |call|
          call.connected_at = Time.now
        end

        before_transition :on => :terminate do |call|
          call.terminated_at = Time.now
        end

        after_transition do |call, transition|
          call.events.log name: transition.event,
            data: {
              call_id: call.id,
              call_state: transition.to,
              conversation_id: call.conversation.id,
              conversation_state: call.conversation.state
            }
        end

        after_transition :on => :conference do |call|
          call.reload.conversation.check_for_successful_transfer
          call.conversation.check_for_successful_resume
          call.conversation.check_for_successful_hold
        end

        after_transition :on => :dial_agent do |call|
          call.reload.conversation.terminate_conferenced_calls call.id
        end

        after_transition any => :terminated do |call|
          call.reload.conversation.check_for_terminate
        end

        after_transition :on => :complete_hold do |call|
          call.reload.conversation.check_for_successful_hold
        end

      end
    end
  end
end
