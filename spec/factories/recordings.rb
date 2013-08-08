FactoryGirl.define do
  factory :recording, class: Telephony::Recording do
    duration 85 * 60 + 35
    url 'http://example.com'
  end
end
