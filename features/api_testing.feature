# Feature: Additional API endpoint testing
# Given: User needs to test various API responses
# When: User accesses different API endpoints
# Then: System provides proper JSON responses
Feature: API Testing
  As a user
  I want to access API endpoints
  So that I can integrate with external services

  @requires_login
  Scenario: Access user API endpoint directly
    When I visit "/api/current_user"
    Then the response should be successful

  @requires_login  
  Scenario: Check API response format
    When I visit "/api/current_user" with JSON headers
    Then the response should contain user data in JSON format

  Scenario: Test root page accessibility
    When I visit the home page
    Then I should see "Leet Planner"
    And the page should load successfully

  Scenario: Test about page content
    When I visit the about page
    Then I should see application information
    And I should see helpful links