FactoryGirl.define do
  factory :conversation, class: Telephony::Conversation do
    sequence :loan_id
    sequence :initiator_id

    factory :connecting_conversation do
      state 'connecting'
    end

    factory :initiating_one_step_transferring_conversation do |c|
      state 'one_step_transferring'
      calls do
        [
          build(:in_progress_call,
                             conversation: nil),
          build(:not_initiated_call,
                             agent: build(:agent),
                             conversation: nil)
        ]
      end
    end

    factory :dequeuing_conversation do |c|
      state 'enqueued'
      calls do
        [
          build(:in_progress_call, :conversation => nil),
          build(:connecting_call, :conversation => nil, agent: build(:agent))
        ]
      end
    end

    factory :one_step_transferring_conversation do |c|
      state 'one_step_transferring'
      calls do
        [
          build(:in_progress_call, :conversation => nil),
          build(:connecting_call, :conversation => nil, agent: build(:agent))
        ]
      end
    end

    factory :in_progress_conversation do
      state 'in_progress'

      factory :in_progress_conversation_with_calls do
        calls do
          [
            build(:in_progress_call, conversation: nil, agent: create(:agent)),
            build(:in_progress_call, conversation: nil),
            build(:connecting_call, conversation: nil, agent: create(:agent))
          ]
        end

        factory :in_progress_hold_conversation_with_calls do
          state 'in_progress_hold'
        end
      end
    end

    factory :two_step_transferring_hold_conversation do
      state 'two_step_transferring_hold'

      factory :two_step_transferring_hold_conversation_with_calls do
        calls do
          [
            build(:in_progress_call, conversation: nil, agent: create(:agent)),
            build(:call, state: 'in_progress_hold', conversation: nil),
            build(:connecting_call, conversation: nil, agent: create(:agent))
          ]
        end
      end
    end

    factory :two_step_transferring_conversation do
      state 'two_step_transferring'

      factory :two_step_transferring_conversation_with_calls do
        calls do
          [
            build(:in_progress_call, conversation: nil, agent: create(:agent)),
            build(:call, state: 'in_progress', conversation: nil),
            build(:connecting_call, conversation: nil, agent: create(:agent))
          ]
        end
      end
    end

    factory :initiating_resume_conversation do
      state 'initiating_resume'
    end

    factory :in_progress_two_step_transfer_conversation do
      state 'in_progress_two_step_transfer'

      factory :in_progress_two_step_transfer_with_calls do
        calls do
          [
            build(:active_agent_leg, conversation: nil),
            build(:in_progress_call, conversation: nil),
            build(:active_agent_leg, conversation: nil)
          ]
        end
      end
    end

    factory :in_progress_two_step_transfer_hold do
      state 'in_progress_two_step_transfer_hold'

      factory :in_progress_two_step_transfer_hold_with_calls do
        calls do
          [
            build(:active_agent_leg, conversation: nil),
            build(:call, state: 'in_progress_hold', conversation: nil),
            build(:active_agent_leg, conversation: nil)
          ]
        end
      end
    end

    factory :terminated_conversation do
      state 'terminated'
    end

    factory :conversation_with_recordings do
      calls do
        [build(:call_with_recording),
         build(:call_with_recording)]
      end
    end

    factory :enqueued_conversation do
      conversation_type 'inbound'
      state 'enqueued'

      calls do
        [
          build(:lone_call, state: 'in_progress')
        ]
      end
    end

    factory :inbound_conversation do
      conversation_type 'inbound'
      calls do
        [
          build(:call, conversation: nil, agent: nil),
          build(:call, conversation: nil, agent: build(:agent))
        ]
      end

      factory :rona_conversation do
        state 'connecting'

        after :create do |conversation|
          conversation.active_agent_leg.connect!
        end
      end
    end

    factory :outbound_conversation do
      conversation_type 'outbound'
      calls do
        [
          build(:lone_call, agent: build(:agent)),
          build(:lone_call)
        ]
      end
    end

    factory :initiating_hold_conversation do
      conversation_type 'outbound'
      state 'initiating_hold'
    end

    factory :in_progress_hold_conversation do
      conversation_type 'outbound'
      state :in_progress_hold
    end
  end
end
