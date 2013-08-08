FactoryGirl.define do
  factory :playable_listener, class: Telephony::PlayableListener do
    sequence :playable_id
    sequence :csr_id
  end
end
