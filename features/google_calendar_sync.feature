# Feature: Google Calendar Synchronization Service
# Given: User has Google Calendar authentication and calendar events
# When: The GoogleCalendarSync service is executed
# Then: Local LeetCode sessions are synchronized with Google Calendar events
Feature: Google Calendar Synchronization
  As a user with Google Calendar integration
  I want my calendar events to be synchronized with my LeetCode sessions
  So that my study sessions are kept in sync between platforms

  Background:
    Given I am a logged-in user with Google Calendar access

  Scenario: Successful calendar synchronization with new events
    Given my Google Calendar has the following events:
      | id        | title                | start_time           | end_time             | status |
      | event_1   | LeetCode Study       | 2025-10-25T14:00:00Z | 2025-10-25T15:00:00Z | confirmed |
      | event_2   | Algorithm Practice   | 2025-10-26T10:00:00Z | 2025-10-26T11:30:00Z | confirmed |
    And I have no existing LeetCode sessions
    When the Google Calendar sync is performed
    Then the sync should be successful
    And I should have 2 new LeetCode sessions created
    And the session for "event_1" should have:
      | title           | LeetCode Study       |
      | scheduled_time  | 2025-10-25T14:00:00Z |
      | duration_minutes| 60                   |
      | status          | scheduled            |
    And the session for "event_2" should have:
      | title           | Algorithm Practice   |
      | scheduled_time  | 2025-10-26T10:00:00Z |
      | duration_minutes| 90                   |
      | status          | scheduled            |

  Scenario: Synchronization updates existing sessions when events change
    Given my Google Calendar has the following events:
      | id        | title                | start_time           | end_time             | status |
      | event_1   | Updated LeetCode     | 2025-10-25T15:00:00Z | 2025-10-25T16:30:00Z | confirmed |
    And I have an existing LeetCode session for "event_1" with:
      | title           | Old LeetCode Study   |
      | scheduled_time  | 2025-10-25T14:00:00Z |
      | duration_minutes| 60                   |
    When the Google Calendar sync is performed
    Then the sync should be successful
    And I should have 0 new LeetCode sessions created
    And I should have 1 LeetCode session updated
    And the session for "event_1" should have:
      | title           | Updated LeetCode     |
      | scheduled_time  | 2025-10-25T15:00:00Z |
      | duration_minutes| 90                   |

  Scenario: Synchronization removes local sessions for deleted Google events
    Given I have existing LeetCode sessions for Google events:
      | google_event_id | title              |
      | event_1         | LeetCode Study     |
      | event_2         | Algorithm Practice |
    And my Google Calendar has the following events:
      | id        | title                | start_time           | end_time             | status |
      | event_1   | LeetCode Study       | 2025-10-25T14:00:00Z | 2025-10-25T15:00:00Z | confirmed |
    When the Google Calendar sync is performed
    Then the sync should be successful
    And I should have 1 LeetCode session deleted
    And the session for "event_2" should be removed

  Scenario: Synchronization handles events without titles
    Given my Google Calendar has the following events:
      | id        | title    | start_time           | end_time             | status |
      | event_1   |          | 2025-10-25T14:00:00Z | 2025-10-25T15:00:00Z | confirmed |
    When the Google Calendar sync is performed
    Then the sync should be successful
    And the session for "event_1" should have:
      | title           | Untitled Session     |
      | description     | Untitled Session     |

  Scenario: Synchronization determines status based on event timing
    Given my Google Calendar has the following events:
      | id        | title                | start_time           | end_time             | status |
      | event_1   | Past Event           | 2025-10-20T14:00:00Z | 2025-10-20T15:00:00Z | confirmed |
      | event_2   | Future Event         | 2025-10-30T14:00:00Z | 2025-10-30T15:00:00Z | confirmed |
    When the Google Calendar sync is performed
    Then the sync should be successful
    And the session for "event_1" should have status "completed"
    And the session for "event_2" should have status "scheduled"

  Scenario: Synchronization skips cancelled events
    Given my Google Calendar has the following events:
      | id        | title                | start_time           | end_time             | status    |
      | event_1   | Cancelled Event      | 2025-10-25T14:00:00Z | 2025-10-25T15:00:00Z | cancelled |
      | event_2   | Active Event         | 2025-10-25T16:00:00Z | 2025-10-25T17:00:00Z | confirmed |
    When the Google Calendar sync is performed
    Then the sync should be successful
    And I should have 1 new LeetCode session created
    And no session should exist for "event_1"
    And the session for "event_2" should exist

  Scenario: Synchronization skips all-day events
    Given my Google Calendar has the following events:
      | id        | title           | date         | all_day |
      | event_1   | All Day Event   | 2025-10-25   | true    |
    When the Google Calendar sync is performed
    Then the sync should be successful
    And I should have 0 new LeetCode sessions created
    And no session should exist for "event_1"

  Scenario: Synchronization handles minimum duration events
    Given my Google Calendar has the following events:
      | id        | title              | start_time           | end_time             | status |
      | event_1   | Very Short Event   | 2025-10-25T14:00:00Z | 2025-10-25T14:00:30Z | confirmed |
    When the Google Calendar sync is performed
    Then the sync should be successful
    And the session for "event_1" should have:
      | duration_minutes| 1 |

  Scenario: Synchronization fails with missing authentication
    Given I am not authenticated with Google Calendar
    When the Google Calendar sync is performed
    Then the sync should fail with error "Not authenticated"

  Scenario: Synchronization fails with expired token that cannot be refreshed
    Given my Google access token is expired
    And the token refresh fails
    When the Google Calendar sync is performed
    Then the sync should fail with error "Authentication expired"

  Scenario: Synchronization handles Google API errors gracefully
    Given my Google Calendar access is configured
    And the Google Calendar API returns an error
    When the Google Calendar sync is performed
    Then the sync should fail with error "Failed to fetch calendar events"

  Scenario: Synchronization skips events that cannot be processed
    Given my Google Calendar has the following events:
      | id        | title                | start_time           | end_time             | status |
      | event_1   | Valid Event          | 2025-10-25T14:00:00Z | 2025-10-25T15:00:00Z | confirmed |
      | event_2   | Problem Event        | 2025-10-25T16:00:00Z | 2025-10-25T17:00:00Z | confirmed |
    And processing "event_2" will cause an error
    When the Google Calendar sync is performed
    Then the sync should be successful
    And I should have 1 new LeetCode session created
    And the session for "event_1" should exist
    And I should have 1 LeetCode session skipped

  Scenario: Synchronization preserves local sessions without Google event IDs
    Given I have existing local-only LeetCode sessions:
      | title              | google_event_id |
      | Manual Session 1   |                 |
      | Manual Session 2   |                 |
    And my Google Calendar has the following events:
      | id        | title                | start_time           | end_time             | status |
      | event_1   | Google Event         | 2025-10-25T14:00:00Z | 2025-10-25T15:00:00Z | confirmed |
    When the Google Calendar sync is performed
    Then the sync should be successful
    And I should have 1 new LeetCode session created
    And the manual sessions should remain unchanged

  Scenario: Class method sync_for_user works correctly
    Given my Google Calendar has the following events:
      | id        | title                | start_time           | end_time             | status |
      | event_1   | LeetCode Study       | 2025-10-25T14:00:00Z | 2025-10-25T15:00:00Z | confirmed |
    When I call GoogleCalendarSync.sync_for_user with my user and session
    Then the sync should be successful
    And I should have 1 new LeetCode session created