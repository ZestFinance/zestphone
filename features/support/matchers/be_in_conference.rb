RSpec::Matchers.define :be_in_conference do |expected|
  match do |actual|
    agent_call_sid = actual.sid
    conversation = actual.conversation

    conferences = twilio_rest_client.account.conferences.list
    agent_conference = conferences.detect { |conference|
      conference.friendly_name == "conference-#{conversation.id}"
    }
    agent_call = agent_conference.participants.get agent_call_sid

    agent_call.should be
  end

  failure_message_for_should do |actual|
    "expected that '#{actual}' would be in the conference"
  end

  failure_message_for_should_not do |actual|
    "expected that '#{actual}' would not be in the conference"
  end
end
