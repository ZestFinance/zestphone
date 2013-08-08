FactoryGirl.define do
  factory :agent, aliases: [:offline_agent], class: Telephony::Agent do
    sequence :csr_id
    csr_type 'A'
    phone_type 'phone'
    phone_number '123-123-1233'

    factory :available_agent do
      status Telephony::Agent::AVAILABLE
    end

    factory :on_a_call_agent do
      status Telephony::Agent::ON_A_CALL
    end

    factory :not_available_agent do
      status Telephony::Agent::NOT_AVAILABLE
    end

    factory :invalid_agent do
      after(:create) do |agent|
        agent.update_attribute :phone_type, 'invalid'
      end
    end
  end
end
