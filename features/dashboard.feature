@dashboard
Feature: Dashboard

  Background:
    Given I am a logged-in user and successfully authenticated with Google

  Scenario: Viewing the dashboard with no current event or timer
    Given I have no ongoing events in my Google Calendar
    And I have not started a manual timer
    When I am on the dashboard page
    Then I should see a welcome message
    And I should not see an event countdown timer
    And I should not see a manual countdown timer

  Scenario: Viewing the dashboard with an ongoing Google Calendar event
    Given I have an ongoing event "Team Sync" in my Google Calendar ending in 30 minutes
    When I am on the dashboard page
    Then I should see "Current Event: Team Sync"
    And I should see a countdown timer with approximately "00:30:00" remaining

  Scenario: Creating and viewing a manual timer
    Given I am on the dashboard page
    When I create a manual timer for "15" minutes
    Then I should be redirected to the dashboard
    And I should see a manual countdown timer with approximately "00:15:00" remaining
    And I should not see a current event

  Scenario: Attempting to create a timer with invalid input
    Given I am on the dashboard page
    When I create a manual timer for "0" minutes
    Then I should be redirected to the dashboard
    And I should not see a manual countdown timer