# Feature: Google Calendar integration for study session planning
# Given: User is authenticated with Google Calendar access
# When: User creates, updates, or deletes calendar events
# Then: Events are synchronized between Google Calendar and local sessions

Feature: Calendar
  As a user, I want to manage my Google Calendar events through the application
  so that I can plan my study sessions effectively.

  Background:
    Given I am a logged-in user and successfully authenticated with Google

  @javascript
  Scenario: A user can create a new timed event
    Given my Google Calendar is ready to create an event
    When I am on the calendar page
    And I open the Add Event form
    And I fill in "Title" with "New Study Session"
    And I fill in "Date" with "2025-10-25"
    And I fill in "Start" with "2025-10-25T14:00"
    And I fill in "End" with "2025-10-25T15:00"
    And I submit the Add Event form
    Then I should see the success message "Event successfully created."
    And a "LeetCodeSession" with the title "New Study Session" should exist

  @javascript
  Scenario: A user can create a new all-day event
    Given my Google Calendar is ready to create an event
    When I am on the calendar page
    And I open the Add Event form
    And I fill in "Title" with "All-Day Hacking"
    And I fill in "Date" with "2025-11-01"
    And I check the "All-day event" checkbox
    And I submit the Add Event form
    Then I should see the success message "Event successfully created."
    And a "LeetCodeSession" for the date "2025-11-01" should exist

  @javascript
  Scenario: A user cannot create an event without a title
    Given I am on the calendar page
    And I open the Add Event form
    And I submit the Add Event form
    Then I should see the error message "Event name is required."

  @javascript
  Scenario: A user can update an existing event
    Given my Google Calendar has an event titled "Old Title" with id "event123"
    When I visit the edit page for the event "event123"
    And I fill in "Title" with "New Updated Title"
    And I click the "Update" button
    Then I should see the success message "Event successfully updated."

  # @javascript
  # Scenario: A user can delete an event
  #  Given my Google Calendar has an event titled "Event to Delete" with id "event456"
  #  When I am on the calendar page
  #  And I click the "Delete" button for "Event to Delete"
  #  Then I should see the success message "Event deleted."

  @javascript
  Scenario: A user with an expired session is asked to log in again
    Given my Google authentication has expired
    When I am on the calendar page
    And I open the Add Event form
    Then I should be redirected to the login page
    And I should see the alert "Your session expired. Please log in again."
