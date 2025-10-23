Feature: User Authentication and Session Management
  As a user
  I want to authenticate and manage my session
  So that I can access the application securely

  Background:
    Given I am not logged in

  Scenario: Accessing debug session page
    When I visit the debug session page
    Then I should see the session data
    And the page status should be 200

  Scenario: OAuth authentication failure
    When I visit the OAuth failure page
    Then I should be redirected to the root page
    And I should see "Login failed"

  Scenario: OAuth authentication failure with custom message
    When I visit the OAuth failure page with message "Custom error"
    Then I should be redirected to the root page
    And I should see "Custom error"

  Scenario: User logout page access
    When I visit the logout page
    Then I should be redirected to the root page

  Scenario: Accessing protected page without login
    When I visit a protected page without being logged in
    Then I should be redirected to the root page
    And I should see "You must be logged in to access this page"

  Scenario: JSON request without authentication
    When I make a JSON request without being logged in to protected endpoint
    Then I should receive an unauthorized response
    And the response should contain "Authentication required"