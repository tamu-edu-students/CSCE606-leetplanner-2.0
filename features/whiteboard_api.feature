Feature: Whiteboard Controller API Endpoints
  As a lobby participant
  I want the whiteboard backend endpoints to respond correctly
  So that collaborative drawing and notes work reliably

  Background:
    Given I am logged in
    And a lobby exists that I own

  Scenario: Fetching whiteboard JSON state
    When I request the whiteboard JSON for the lobby
    Then the JSON response should include "svg_data"

  Scenario: Updating SVG succeeds with data
    When I post SVG data "<svg></svg>" to the whiteboard
    Then the JSON response should indicate success

  Scenario: Updating SVG fails without data
    When I post empty SVG data to the whiteboard
    Then the JSON response should indicate error

  Scenario: Clearing whiteboard resets SVG
    When I clear the whiteboard
    Then the whiteboard SVG should reset to default grid

  Scenario: Unauthorized notes update blocked
    Given another user without notes permission is in the lobby
    When that user attempts to update the whiteboard notes
    Then the notes update should be rejected

  Scenario: Authorized notes update succeeds
    Given I grant myself notes edit permission
    When I update notes via API to "Collab notes"
    Then the notes should persist as "Collab notes"
