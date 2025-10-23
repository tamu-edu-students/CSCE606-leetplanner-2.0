# Feature: Dashboard functionality and user data display
# Given: User is authenticated and has session data
# When: User accesses dashboard with various data states
# Then: Dashboard displays appropriate content and handles edge cases
Feature: Dashboard Management
  As a logged-in user
  I want to access my dashboard
  So that I can view my coding progress and statistics

  Background:
    Given I am a logged-in user

  Scenario: Visit dashboard page
    When I visit the dashboard page
    Then I should see "Dashboard"

  Scenario: Dashboard page loads successfully
    When I visit the dashboard page
    Then the page should load without errors
    And I should see navigation elements