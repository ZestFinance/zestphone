require 'state_machine'

module Telephony
  module ConversationStateMachine
    extend ActiveSupport::Concern

    included do
      state_machine :state, :initial => :initiated do

        event :play_message do
          transition :initiated => :playing_message
        end

        event :play_closed_greeting do
          transition :initiated => :terminated
        end

        event :enqueue do
          transition :playing_message => :enqueued
        end

        event :connect do
          transition [:initiated, :enqueued] => :connecting
        end

        event :rona do
          transition :connecting => :enqueued
        end

        event :start do
          transition :connecting => :in_progress
        end

        event :initiate_one_step_transfer do
          transition [:in_progress, :in_progress_hold] => :one_step_transferring
        end

        event :complete_one_step_transfer do
          transition :one_step_transferring => :in_progress
        end

        event :fail_one_step_transfer do
          transition :one_step_transferring => :leaving_voicemail
        end

        event :initiate_two_step_transfer do
          transition :in_progress => :two_step_transferring,
                     :in_progress_hold => :two_step_transferring_hold
        end

        event :complete_two_step_transfer do
          transition :two_step_transferring => :in_progress_two_step_transfer,
                     :two_step_transferring_hold => :in_progress_two_step_transfer_hold
        end

        event :leave_two_step_transfer do
          transition :in_progress_two_step_transfer => :in_progress,
                     :in_progress_two_step_transfer_hold => :in_progress_hold
        end

        event :customer_left_two_step_transfer do
          transition :in_progress_two_step_transfer => :agents_only,
                     :in_progress_two_step_transfer_hold => :agents_only
        end

        event :fail_two_step_transfer do
          transition :two_step_transferring => :in_progress,
                     :two_step_transferring_hold => :in_progress_hold
        end

        event :initiate_hold do
          transition :in_progress => :initiating_hold,
                     :in_progress_two_step_transfer => :initiating_two_step_transfer_hold
        end

        event :complete_hold do
          transition :initiating_hold => :in_progress_hold,
                     :initiating_two_step_transfer_hold => :in_progress_two_step_transfer_hold
        end

        event :initiate_resume do
          transition :in_progress_hold => :initiating_resume,
                     :in_progress_two_step_transfer_hold => :initiating_two_step_transfer_resume
        end

        event :complete_resume do
          transition :initiating_resume => :in_progress,
                     :initiating_two_step_transfer_resume => :in_progress_two_step_transfer
        end

        event :leave_voicemail do
          transition all - [:leaving_voicemail, :terminated] => :leaving_voicemail
        end

        event :terminate do
          transition all - [:terminated] => :terminated
        end

        after_transition do |conversation, transition|
          conversation.events.log name: transition.event,
            data: {
              conversation_id: conversation.id,
              conversation_state: transition.to
            }
        end
      end
    end
  end
end
