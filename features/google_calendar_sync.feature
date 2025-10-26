Feature: Google Calendar Synchronization
  The GoogleCalendarSync service syncs Google Calendar events with local LeetCode sessions.

  Background:
    Given a user exists with valid Google credentials

  Scenario: Successful calendar sync
    When the user performs a calendar sync
    Then the sync result should indicate success
    And the sync result should include sync statistics

  Scenario: Sync fails due to authentication error
    Given the user has invalid Google credentials
    When the user performs a calendar sync
    Then the sync result should indicate failure
    And the error message should be "Not authenticated"

  Scenario: Sync fails due to Google API error
    Given the Google Calendar API raises an error
    When the user performs a calendar sync
    Then the sync result should indicate failure
    And the error message should be "Failed to fetch calendar events"

  Scenario: Sync fails due to unexpected error
    Given an unexpected error occurs during sync
    When the user performs a calendar sync
    Then the sync result should indicate failure
    And the error message should contain "Unexpected failure"

  Scenario: Sync using class method
    Given a user exists with valid Google credentials
    When I call the class method sync_for_user for the user
    Then the sync result should indicate success

  Scenario: Sync fails due to expired token
    Given a user exists with valid Google credentials
    And the Google token is expired
    When the user performs a calendar sync
    Then the sync result should indicate failure
    And the error message should be "Authentication expired"

  Scenario: Skipped events are handled
    Given a user exists with valid Google credentials
    And the Google Calendar API returns an event that fails to sync
    When the user performs a calendar sync
    Then the sync result should indicate success
    And the synced, updated, skipped, and deleted counts should be present

  Scenario: Past events are marked completed
    Given a user exists with valid Google credentials
    And the Google Calendar API returns a past event
    When the user performs a calendar sync
    Then the sync result should indicate success
    And the event should be considered completed

  Scenario: Skipped events are handled
    Given a user exists with valid Google credentials
    And the Google Calendar API returns an event that cannot be synced
    When the user performs a calendar sync
    Then the sync result should indicate success
    And the synced, updated, skipped, and deleted counts should be present

  Scenario: Token refresh succeeds for expired token
    Given a user exists with valid Google credentials
    And the Google token is expired but refresh succeeds
    When the user performs a calendar sync
    Then the sync result should indicate success
    And the synced, updated, skipped, and deleted counts should be present

  Scenario: Events with no changes are skipped
    Given a user exists with valid Google credentials
    And the Google Calendar API returns an event that does not change
    When the user performs a calendar sync
    Then the sync result should indicate success
    And the synced, updated, skipped, and deleted counts should be present

  Scenario: Updated events are counted correctly
    Given a user exists with valid Google credentials
    And the Google Calendar API returns an event that has been updated
    When the user performs a calendar sync
    Then the sync result should indicate success
    And the synced, updated, skipped, and deleted counts should be present

  Scenario: Updated events are counted
    Given a user exists with valid Google credentials
    And the Google Calendar API returns an event that triggers an update
    When the user performs a calendar sync
    Then the sync result should indicate success
    And the synced, updated, skipped, and deleted counts should be present

  Scenario: Events with no changes are skipped
    Given a user exists with valid Google credentials
    And the Google Calendar API returns an event that does not change
    When the user performs a calendar sync
    Then the sync result should indicate success
    And the synced, updated, skipped, and deleted counts should be present
