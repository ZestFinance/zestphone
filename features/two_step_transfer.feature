@wopr @javascript @teardown_timeout
Feature: Two step transfer
  As an agent1
  I want to transfer a customer to agent2
  So I agent2 can work with a customer

  Scenario: Two step transfer
    Given "agent1" is on the telephony widget page
    And the status should be "available"
    And "agent1" calls the "customer"
    And "agent1" initiates a two step transfer to "agent2"
    When "agent1" hangs up
    Then the message text should say "Call Ended"
    And the status should be "not available"
    And "agent2" is in conference call
    And customer is in conference call
    And I wait 10 seconds
