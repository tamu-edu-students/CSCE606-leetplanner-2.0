@dashboard
Feature: Dashboard Display and Timer Functionality
  As a user, I want to see my current event status and manage a focus timer
  so that I can track my productivity.

  Background:
    Given I am a logged-in user and successfully authenticated with Google

  Scenario: Viewing an empty dashboard (no event, no timer)
    Given my Google Calendar has no ongoing events
    And I have no active manual timer
    When I visit the dashboard page
    Then I should see the timer display showing "00:00:00"
    And I should not see a current event banner

  Scenario: Viewing an active timed event from Google Calendar
    Given my Google Calendar has an ongoing event "Team Sync" ending in 30 minutes
    When I visit the dashboard page
    Then I should see the current event title "Team Sync"
    And I should see a countdown timer with approximately "00:30:00" remaining

  Scenario: Viewing an active all-day event from Google Calendar
    Given my Google Calendar has an ongoing all-day event "Team Workshop"
    When I visit the dashboard page
    Then I should see the current event title "Team Workshop"
    And I should see a countdown timer showing the time until midnight

  Scenario: Viewing a recently expired Google Calendar event
    Given my Google Calendar has an event "Review Meeting" that just ended
    When I visit the dashboard page
    Then I should not see a current event banner
    And I should see the timer display showing "00:00:00"

  Scenario: Creating and viewing a manual focus timer
    Given my Google Calendar has no ongoing events
    When I create a manual timer for "15" minutes
    Then I should see a countdown timer with approximately "00:15:00" remaining
    And I should not see a current event banner

  Scenario: Creating a manual timer with invalid input
    Given my Google Calendar has no ongoing events
    When I create a manual timer for "0" minutes
    Then I should see the timer display showing "00:00:00"

  Scenario: Viewing the dashboard with an expired manual timer
    Given I have a manual timer that expired 5 minutes ago
    When I visit the dashboard page
    Then I should see the timer display showing "00:00:00"
    And the timer should be cleared from my session

  Scenario: Handling Google Calendar API failures
    Given the Google Calendar API is unavailable
    When I visit the dashboard page
    Then I should see a calendar sync error message
    And I should see the timer display showing "00:00:00"