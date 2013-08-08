@wopr @javascript @teardown_timeout
Feature: One step transfer
  As an agent1
  I want to make a one step transfer to agent2
  So I agent2 can work with a customer

  Scenario: One step transfer
    Given "agent1" is on the telephony widget page
    And the status should be "available"
    And "agent1" calls the "customer"
    And "agent1" initiates a one step transfer to "agent2"
    And I wait 10 seconds
