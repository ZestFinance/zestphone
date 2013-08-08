module Telephony::Events
  FactoryGirl.define do
    factory :event, class: Base do
      conversation factory: :outbound_conversation

      factory :agent_call_connect_event,
        class: Connect,
        aliases: [:publishable_event] do
        call_id { conversation.active_agent_leg.id }
      end

      factory :borrower_call_connect_event,
        class: Connect,
        aliases: [:non_publishable_event] do
        call_id { conversation.customer.id }
      end

      factory :conversation_connect_event, class: Connect do
        call_id nil
      end

      factory :inbound_call_connect_event,
              class: Connect do
        conversation factory: :inbound_conversation
        call_id { conversation.customer.id }
      end

      factory :conversation_start_event, class: Start do
      end

      factory :conversation_answer_event, class: Answer do
        call_id { conversation.active_agent_leg.id }
      end

      factory :conversation_answer_event_for_customer, class: Answer do
        call_id { conversation.customer.id }
      end

      factory :conversation_conference_event, class: Conference do
        call_id { conversation.active_agent_leg.id }
      end

      factory :conversation_conference_event_for_customer, class: Conference do
        call_id { conversation.customer.id }
      end

      factory :csr_call_ended_event, class: NoAnswer do
        call_id { conversation.active_agent_leg.id }
      end

      factory :borrower_call_ended_event, class: Busy do
        call_id { conversation.customer.id }
      end

      factory :conversation_ended_event, class: Terminate do
        call_id nil
      end

      factory :two_step_transfer_initiated_event, class: InitiateTwoStepTransfer do
        call_id nil
        conversation do
          transferrer = FactoryGirl.create :agent,
            name: 'Transferrer',
            phone_ext: '10'

          transferee = FactoryGirl.create :agent,
            name: 'Transferree',
            phone_ext: '11'

          conversation = FactoryGirl.create :conversation,
            transferee: transferee
          conversation.calls << FactoryGirl.create(:call, agent: transferrer)
          conversation.calls << FactoryGirl.create(:call)
          conversation.calls << FactoryGirl.create(:call, agent: transferee)
          conversation
        end
      end

      factory :two_step_transfer_failed_event, class: FailTwoStepTransfer do
        call_id nil
        conversation do
          transferrer = FactoryGirl.create :agent,
            name: 'Transferrer',
            phone_ext: '10'

          transferee = FactoryGirl.create :agent,
            name: 'Transferree',
            phone_ext: '11'

          conversation = FactoryGirl.create :conversation,
            transferee: transferee
          FactoryGirl.create(:call,
                             agent: transferrer,
                             conversation: conversation)
          FactoryGirl.create(:call,
                             conversation: conversation)
          FactoryGirl.create(:terminated_call,
                             agent: transferee,
                             conversation: conversation)
          conversation
        end
        message_data do
          agent_messages
        end
      end

      factory :two_step_transfer_completed_event, class: CompleteTwoStepTransfer do
        call_id nil
        conversation do
          transferrer = FactoryGirl.create :agent,
            name: 'Transferrer',
            phone_ext: '10'

          transferee = FactoryGirl.create :agent,
            name: 'Transferree',
            phone_ext: '10'

          conversation = FactoryGirl.create :conversation,
            transferee: transferee
          conversation.calls << FactoryGirl.create(:call, agent: transferrer)
          conversation.calls << FactoryGirl.create(:call)
          conversation.calls << FactoryGirl.create(:call, agent: transferee)
          conversation
        end
      end

      factory :leave_two_step_transfer_event, class: LeaveTwoStepTransfer do
        call_id nil
        conversation do
          conversation = FactoryGirl.create :conversation
          FactoryGirl.create(:inactive_agent_leg,
                             conversation: conversation)
          FactoryGirl.create(:customer_leg,
                             conversation: conversation)
          FactoryGirl.create(:active_agent_leg,
                             conversation: conversation)
          conversation
        end
      end

      factory :initiate_one_step_transfer_event, class: InitiateOneStepTransfer do
        call_id nil
        conversation do
          transferrer = FactoryGirl.create :agent,
            name: 'Some Name',
            phone_ext: '10'

          transferee = FactoryGirl.create :agent,
            name: 'Some Name',
            phone_ext: '10'

          conversation = FactoryGirl.create :conversation,
            transferee: transferee
          FactoryGirl.create(:active_agent_leg,
                             conversation: conversation,
                             agent: transferrer)
          FactoryGirl.create(:customer_leg,
                             conversation: conversation)
          FactoryGirl.create(:active_agent_leg,
                             conversation: conversation,
                             agent: transferee)
          conversation
        end
      end

      factory :complete_one_step_transfer_event, class: CompleteOneStepTransfer do
        call_id nil
        conversation do
          transferrer = FactoryGirl.create :agent,
            name: 'Some Name',
            phone_ext: '10'

          transferee = FactoryGirl.create :agent,
            name: 'Some Name',
            phone_ext: '10'

          conversation = FactoryGirl.create :conversation,
            transferee: transferee
          FactoryGirl.create(:inactive_agent_leg,
                             conversation: conversation,
                             agent: transferrer)
          FactoryGirl.create(:customer_leg,
                             conversation: conversation)
          FactoryGirl.create(:active_agent_leg,
                             conversation: conversation,
                             agent: transferee)
          conversation
        end
      end

      factory :one_step_transfer_failed_event, class: FailOneStepTransfer do
        call_id nil
        conversation do
          transferrer = FactoryGirl.create :agent,
            name: 'Transferrer',
            phone_ext: '10'

          transferee = FactoryGirl.create :agent,
            name: 'Transferree',
            phone_ext: '11'

          conversation = FactoryGirl.create :conversation,
            transferee: transferee
          FactoryGirl.create(:terminated_call,
                             agent: transferrer,
                             conversation: conversation)
          FactoryGirl.create(:call,
                             conversation: conversation)
          FactoryGirl.create(:no_answer_call,
                             agent: transferee,
                             conversation: conversation)
          conversation
        end
        message_data do
          agent_messages
        end
      end

      factory :complete_hold_event, class: CompleteHold
      factory :complete_resume_event, class: CompleteResume

      factory :leave_voicemail_event, class: LeaveVoicemail do
        conversation do
          transferrer = FactoryGirl.create :agent,
            name: 'Some Name',
            phone_ext: '10'

          transferee = FactoryGirl.create :agent,
            name: 'Other Name',
            phone_ext: '11',
            status: 'offline'

          conversation = FactoryGirl.create :conversation,
            transferee: transferee
          FactoryGirl.create(:active_agent_leg,
                             conversation: conversation,
                             agent: transferrer)
          FactoryGirl.create(:customer_leg,
                             conversation: conversation)
          FactoryGirl.create(:not_initiated_call,
                             conversation: conversation,
                             agent: transferee)
          conversation
        end
      end

      factory :answer_event, class: Answer
    end
  end
end
