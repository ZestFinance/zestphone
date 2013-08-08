########################
### HIGH LEVEL STEPS ###
########################

Given /^"([^"]*)" calls the "([^"]*)"$/ do |person_one, person_two|
  step %Q{I enter the customer's phone number}
  step %Q{"#{person_one}" clicks the "Call" button}
  step %Q{the message text should say "Ringing"}
  step %Q{"#{person_one}" should be on a call with the "#{person_two}"}
  step %Q{the message text should say "Connected"}
  step %Q{the status should be "on a call"}
end

Given /^"([^"]*)" initiates a two step transfer to "([^"]*)"$/ do |agent_one, agent_two|
  step %Q{"#{agent_two}" is available}
  step %Q{I click on "the transfer button"}
  step %Q{I should see "#{agent_two}" within "the agents list"}
  step %Q{I choose "#{agent_two}" from a transfer dropdown}
  step %Q{"two" step transfer is chosen}
  step %Q{"#{agent_one}" clicks the "Initiate Transfer" button}
  step %Q{the message text should say "Ringing A - #{agent_two}"}
  step %Q{the message text should say "Connected to A - #{agent_two}"}
  step %Q{"#{agent_one}" is in conference call}
  step %Q{"#{agent_two}" is in conference call}
  step %Q{customer is in conference call}
end

Given /^"([^"]*)" initiates a one step transfer to "([^"]*)"$/ do |agent_one, agent_two|
  step %Q{"#{agent_two}" is available}
  step %Q{I click on "the transfer button"}
  step %Q{I should see "#{agent_two}" within "the agents list"}
  step %Q{I choose "#{agent_two}" from a transfer dropdown}
  step %Q{"one" step transfer is chosen}
  step %Q{"#{agent_one}" clicks the "Initiate Transfer" button}
  sleep 2
  step %Q{the status should be "not available"}
  step %Q{the message text should say "Call Ended"}
end

Given /^"([^"]*)" puts the customer on hold$/ do |agent_one|
  step %Q{"the hold button" should be visible}
  step %Q{"agent1" clicks the "Hold" button}
  step %Q{"the resume button" should be visible}
  step %Q{the customer is on hold}
  step %Q{"agent1" is in conference call}
end

Given /^"([^"]*)" resumes conversation with a customer$/ do |agent_one|
  step %Q{"the resume button" should be visible}
  step %Q{"agent1" clicks the "Resume" button}
  step %Q{"agent1" is in conference call}
  step %Q{customer is in conference call}
  step %Q{"the hold button" should be visible}
end

########################
### LOW LEVEL STEPS ###
########################

Given /^"([^"]*)" is on the telephony widget page$/ do |agent|
  visit "/?agent-number=#{bot(agent).phone_number}&csr-id=#{bot(agent).id}"
end

Then /^"([^"]*)" should be visible$/ do |element|
  selector = selector_for element

  wait_until_ignoring_errors do
    page.should have_selector(selector, visible: true)
  end
end

Then /^"([^"]*)" step transfer is chosen$/ do |one_or_two|
  find("#transfer_type_#{one_or_two}_step").click
end

Then /^the status should be "([^"]*)"$/ do |status|
  find('button.agent-status').should have_content(status.upcase)
end

Then /^the customer is on hold$/ do
  conversation = Telephony::Conversation.first
  conversation.customer.should be_on_hold
end

Then /^"([^"]*)" is in conference call/ do |agent|
  conversation = Telephony::Conversation.first
  agent_leg = conversation.active_agent_legs.detect do |agent_leg|
    agent_leg.agent.id == bot(agent).id
  end

  agent_leg.should be
  agent_leg.should be_in_conference
end

Then /^customer is in conference call/ do
  conversation = Telephony::Conversation.first
  conversation.customer.should be_in_conference
end

When /^I enter the customer's phone number/ do
  fill_in "number", with: bot(:customer).phone_number
end

When /^"([^"]*)" clicks the "([^"]*)" button$/ do |person, text|
  click_button text
end

# click on specific element to avoid an ambiguous match by text
When /^I click on "(.*?)"$/ do |locator|
  selector = selector_for locator

  wait_until_ignoring_errors do
    page.should have_selector(selector, visible: true)
    find(selector).click
  end
end

Then /^the message text should say "(.*?)"$/ do |message|
  step %Q{I should see "#{message}" within ".friendly-message"}
end

And /^"(.*?)" is available/ do |agent|
  Telephony::Agent.create! csr_id: bot(agent).id,
    phone_number: bot(agent).phone_number,
    status: 'available',
    name: agent,
    csr_type: "A",
    phone_ext: rand(100)
end

Then /^I choose "(.*?)" from a transfer dropdown$/ do |agent|
  all('ol.agents-list li.available').detect {|el| el.text =~ /#{agent}/}.click
end

When /^I wait (\d+) seconds$/ do |number_of_seconds|
  sleep number_of_seconds.to_i
end

When /^"(.*?)" hangs up$/ do |person|
  bot(person).current_call.hangup
end

Then /^"(.*?)" should( not)? be on a call with the "(.*?)"$/ do |one_person, yes_it_should, another_person|
  yes_it_should = yes_it_should.present? ? false : true

  if yes_it_should
    bot(one_person).should be_on_a_call
    bot(another_person).should be_on_a_call
    bot(one_person).should be_on_a_call_with(bot(another_person))
  else
    bot(one_person).should_not be_on_a_call
    bot(another_person).should_not be_on_a_call
    bot(one_person).should_not be_on_a_call_with(bot(another_person))
  end
end
