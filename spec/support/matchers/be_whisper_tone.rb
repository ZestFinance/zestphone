RSpec::Matchers.define :be_whisper_tone do |expected|
  match do |actual|
    xml = Nokogiri::XML actual
    root = xml.root
    root.should be
    root.name.should == 'Response'
    root.should have(:no).children
  end

  failure_message_for_should do |actual|
    "expected that '#{actual}' would be a whisper tone (<Response />)"
  end

  failure_message_for_should_not do |actual|
    "expected that '#{actual}' would not be a whisper tone (<Response />)"
  end
end

RSpec::Matchers.define :be_hangup do |expected|
  match do |actual|
    xml = Nokogiri::XML actual
    root = xml.root
    root.should be
    hangup = xml.at '/Response/Hangup'
    hangup.should be
  end

  failure_message_for_should do |actual|
    "expected that '#{actual}' would be a hangup (<Response><Hangup/></Response>)"
  end

  failure_message_for_should_not do |actual|
    "expected that '#{actual}' would not be a hangup (<Response><Hangup/></Response>)"
  end
end
