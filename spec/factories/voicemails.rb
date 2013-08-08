FactoryGirl.define do
  factory :voicemail, class: Telephony::Voicemail do
    sequence :csr_id
    duration 1
    call
    sequence(:url) {|n| "http://example.com/#{n}"}
  end
end
