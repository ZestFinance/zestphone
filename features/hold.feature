@wopr @javascript @teardown_timeout
Feature: Hold
  As an agent
  I want to put the customer on hold
  So I can talk to another agent without the the customer hearing us

  Background:
    Given "agent1" is on the telephony widget page
    And the status should be "available"
    When "agent1" calls the "customer"

  Scenario: Hold / Resume
    Then "agent1" puts the customer on hold
    And "agent1" resumes conversation with a customer
    And I wait 10 seconds
