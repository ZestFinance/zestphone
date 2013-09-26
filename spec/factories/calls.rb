FactoryGirl.define do
  factory :call, class: Telephony::Call, aliases: [:participant] do
    conversation
    sid
    number '562-555-5555'
    sequence :participant_id

    factory :lone_call do
      conversation nil
    end

    factory :terminated_call do
      state 'terminated'
    end

    factory :not_initiated_call do
      state 'not_initiated'
    end

    factory :connecting_call do
      state 'connecting'
    end

    factory :in_progress_call do
      state 'in_progress'
    end

    factory :in_conference_call do
      state 'in_conference'
    end

    factory :holding_agent_call do
      state 'in_progress'
      conversation do
        build :conversation, state: 'initiating_hold'
      end
    end

    factory :holding_cust_call do
      state 'in_progress'
      conversation do
        build :conversation, state: 'initiating_hold'
      end
    end

    factory :failed_call do
      sid nil
      state 'in_progress'
    end

    factory :no_answer_call do
      state 'terminated'
    end

    factory :transferred_call do
      factory :one_step_transfer_call do
        conversation do
          build :conversation, state: 'one_step_transferring', transfer_type: 'one_step'
        end
      end

      factory :two_step_transfer_call do
        conversation do
          build :conversation, state: 'two_step_transferring', transfer_type: 'two_step'
        end
      end
    end

    factory :transferred_participant do
      number '555-555-5555'
      conversation do
        build :conversation
      end
    end

    factory :call_with_recording do
      recordings do
        [build(:recording)]
      end
    end

    factory :connecting_agent_leg do
      agent
      state :connecting
    end

    factory :active_agent_leg do
      agent
      state :in_progress
    end

    factory :customer_leg do
      agent nil
      state :in_progress
    end

    factory :inactive_agent_leg do
      agent
      state :terminated
    end
  end

  sequence :sid do |number|
    "sid-#{number}"
  end
end
