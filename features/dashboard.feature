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

  Scenario: Handling Google Calendar API failure gracefully
    Given the Google Calendar API is experiencing issues
    When I am on the dashboard page
    Then I should see a calendar sync error message
    And I should still be able to create a manual timer

  Scenario: Viewing the dashboard with an all-day event
    Given I have an all-day event "Team Workshop" in my Google Calendar
    When I am on the dashboard page
    Then I should see "Current Event: Team Workshop"
    And I should see a countdown timer showing remaining time until midnight

  Scenario: Expired timer handling
    Given I am on the dashboard page
    And I have a timer that expired 5 minutes ago
    When I refresh the page
    Then I should not see a manual countdown timer
    And the timer should be cleared from my session

  Scenario: Timer remaining time display
    Given I am on the dashboard page
    When I create a manual timer for "120" minutes
    Then I should see a manual countdown timer with approximately "02:00:00" remaining
