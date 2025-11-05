Feature: OAuth Controller Integration Testing
  As a developer
  I want to test OAuth integration scenarios
  So that all controller code paths are covered

  Scenario: Visit sessions create endpoint directly
    When I visit the sessions create endpoint
    Then I should get a response

  Scenario: Visit sessions destroy with user logged in
    Given I create a test user with tokens
    When I visit the sessions destroy endpoint
    Then the response should clear tokens