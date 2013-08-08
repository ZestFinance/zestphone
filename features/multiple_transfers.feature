@wopr @javascript @teardown_timeout
Feature: Multiple transfers
  As an agent1
  I want to transfer a customer to agent2 and agent3 after that
  So I agent3 can work with a customer

  Scenario: Two step transfer followed by a two step transfer
    Given "agent1" is on the telephony widget page
    And the status should be "available"
    And "agent1" calls the "customer"
    And "agent1" initiates a two step transfer to "agent2"
    When "agent2" hangs up
    Then the message text should say "Connected"
    And I wait 1 seconds
    And "agent1" initiates a two step transfer to "agent3"
    And I wait 10 seconds

  Scenario: One step transfer followed by a two step transfer
    Given "agent1" is on the telephony widget page
    And the status should be "available"
    And "agent1" calls the "customer"
    And "agent1" initiates a one step transfer to "agent2"
    When "agent2" is on the telephony widget page
    And the status should be "on a call"
    And "agent2" initiates a two step transfer to "agent3"
    And I wait 10 seconds
