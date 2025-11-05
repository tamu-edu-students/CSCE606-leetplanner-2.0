Feature: Collaborative Whiteboard
  As a lobby participant
  I want to collaborate on a shared whiteboard
  So that we can sketch ideas together

  Background:
    Given I am logged in
    And a lobby exists that I own
    And I visit the lobby page

  Scenario: Non-JavaScript fallback displays basic controls
    Then I should see "Shared Whiteboard"
    And I should see "Add Content (Works without JavaScript)"

  Scenario: Adding a rectangle via fallback form
    When I add a rectangle to the whiteboard
    Then I should see a success message

  Scenario: Updating shared notes
    When I update the whiteboard notes to "Brainstorming session" 
    Then I should see "Notes updated." on the lobby page
