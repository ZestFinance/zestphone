require_dependency 'telephony/providers/twilio/application_controller'

module Telephony
  module Providers
    module Twilio
      class CallsController < ApplicationController
        around_filter :lock_conversation, except: :leave_queue
        around_filter :lock_inbound_conversation, only: :leave_queue

        def connect
          @connecting_call = @call.conversation.not_initiated_call
          @call.answer!
          @connecting_call.connect!
        end

        def child_answered
          @call.sid ||= params[:CallSid]
          @call.answer!

          if @call.conversation.one_step_transferring?
            @call.conversation.complete_one_step_transfer!
          else
            @call.conversation.start!
          end

          render :whisper_tone
        end

        def child_detached
          @child_call = @call.conversation.child_call(params[:DialCallSid])
          @child_call.record! params
          @child_call.sid ||= params[:DialCallSid]

          case params[:DialCallStatus]
          when 'completed'
            if @call.conversation.two_step_transferring?
              render_conference
            elsif @call.conversation.initiating_hold?
              if @call.agent
                render_conference
              else
                render_complete_hold
              end
            elsif child_hung_up?
              @child_call.terminate!
            end
          else
            case params[:DialCallStatus]
            when 'no-answer'
              @child_call.no_answer!
            when 'failed', 'canceled'
              @child_call.call_fail!
            when 'busy'
              @child_call.busy!
            end

            if @child_call.conversation.enqueued?
              render 'telephony/providers/twilio/inbound_calls/enqueue'
            elsif @child_call.conversation.leaving_voicemail?
              render 'telephony/providers/twilio/voicemails/new'
            end
          end
        end

        def join_conference
          @call.conference! unless @call.in_conference?
        end

        def complete_hold
          @call.complete_hold!
        end

        def dial
          @child_call = @call.conversation.calls.last
          if @call.conversation.leaving_voicemail?
            render 'telephony/providers/twilio/voicemails/new'
          end
        end

        def done
          @call.record! params

          unless @call.terminated?
            case params[:CallStatus]
            when 'no-answer'
              @call.no_answer!
            when 'failed'
              @call.call_fail!
            when 'busy'
              @call.busy!
            when 'completed'
              @call.terminate!
            end
          end
        end

        def leave_queue
          unless @call.terminated?
            case params[:QueueResult]
            when 'hangup'
              @call.terminate!
            when 'queue-full', 'error', 'system-error'
              Rails.logger.error "Twilio provider - QueueResult: #{params[:QueueResult]} - Sid: #{@call.sid}"
              @call.terminate!
            end
          end

          head :ok
        end

        private

        def lock_conversation
          @call = Call.find params[:id]
          Conversation.find_with_lock(@call.conversation_id) do
            yield
          end
        end

        def lock_inbound_conversation
          @call = Call.find params[:id]
          Conversation.find_inbound_calls_with_lock(@call.conversation_id) do
            yield
          end
        end
      end
    end
  end
end

