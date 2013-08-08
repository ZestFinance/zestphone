@wopr @javascript @teardown_timeout
Feature: Outbound call
  As an agent1
  I want to call a customer
  So I can service a customer

  Scenario: Outbound call
    Given "agent1" is on the telephony widget page
    And the status should be "available"
    And "agent1" calls the "customer"
    When "agent1" hangs up
    And "customer" hangs up
    Then the message text should say "Call Ended"
    And the status should be "not available"
    And I wait 10 seconds
