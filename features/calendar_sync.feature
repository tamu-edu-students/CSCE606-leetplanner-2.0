Feature: Session Controller Functionality
  As a user
  I want to test session management features
  So that the application handles sessions correctly

  Scenario: Access debug session endpoint
    When I visit the debug session page
    Then I should see the session data
    And the page status should be 200

  Scenario: Handle OAuth failure
    When I visit the OAuth failure page with message "Test failure"
    Then I should be redirected to the root page
    And I should see "Test failure"

  Scenario: Logout functionality
    When I visit the logout page
    Then I should be redirected to the root page