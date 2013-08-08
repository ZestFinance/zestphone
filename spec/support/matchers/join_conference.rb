RSpec::Matchers.define :join_conference do |expected|
  chain :with_id do |id|
    @id = id
  end

  match do |actual|
    xml = Nokogiri::XML response.body
    dial = xml.at '/Response/Dial'
    dial.attributes['record'].value.should == 'false'
    conference = dial.at('Conference')
    conference.attributes['beep'].value.should == 'false'
    @id ||= actual.conversation_id
    conference.text.should == "conference-#{@id}"
  end

  failure_message_for_should do |actual|
    "expected that '#{actual}' would join the conference"
  end

  failure_message_for_should_not do |actual|
    "expected that '#{actual}' would not join the conference"
  end
end
