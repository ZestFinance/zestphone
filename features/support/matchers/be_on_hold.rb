RSpec::Matchers.define :be_on_hold do |expected|
  match do |actual|
    customer_sid = actual.sid

    queues = twilio_rest_client.account.queues.list
    hold_queue = queues.detect {|queue| queue.friendly_name == 'hold'}
    customer_on_hold = hold_queue.members.get customer_sid

    customer_on_hold.should be
  end

  failure_message_for_should do |actual|
    "expected that '#{actual}' would be in the 'hold' queue"
  end

  failure_message_for_should_not do |actual|
    "expected that '#{actual}' would not be in the 'hold' queue"
  end
end
