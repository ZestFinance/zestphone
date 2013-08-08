RSpec::Matchers.define :complete_hold do |expected|
  chain :with_id do |id|
    @id = id
  end

  match do |actual|
    xml = Nokogiri::XML response.body
    enqueue = xml.at('/Response/Enqueue')
    enqueue.text.should == 'hold'
    enqueue.attributes['action'].value.should =~ %r{/zestphone/providers/twilio/calls/\d+/leave_queue}
  end

  failure_message_for_should do |actual|
    "expected that '#{actual}' would be put in the hold queue"
  end

  failure_message_for_should_not do |actual|
    "expected that '#{actual}' would not be put in the hold queue"
  end
end
