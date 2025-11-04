Feature: Managing Lobby Notes
  As a lobby member, I want to view and edit a shared note for the lobby,
  so that we can coordinate and share information.

  Background:
    Given a lobby exists, owned by "Lobby Owner"
    And "Editor Member" is a member of the lobby with edit permissions
    And "Viewer Member" is a member of the lobby without edit permissions
    And "Other User" is an authenticated user who is not a member of the lobby

  Scenario: Viewing an existing note as a viewer
    Given the lobby has a note with content "This is the initial note."
    And I am logged in as "Viewer Member"
    When I go to the lobby's note page
    Then I should be on the lobby note page
    And I should see "This is the initial note."
    And I should not see a button to "Save Note"

  Scenario: Creating a new note as an editor
    Given the lobby does not have a note
    And I am logged in as "Editor Member"
    When I go to the lobby's edit note page
    Then I should be on the edit lobby note page
    When I fill in the note content with "This is a brand new note."
    And I click "Save Note"
    Then I should be redirected to the lobby's main page
    And I should see "Note updated successfully"
    When I go to the lobby's note page
    Then I should see "This is a brand new note."

  Scenario: Updating an existing note as the owner
    Given the lobby has a note with content "This is the initial note."
    And I am logged in as "Lobby Owner"
    When I go to the lobby's edit note page
    Then I should see "This is the initial note."
    When I fill in the note content with "This is the updated note."
    And I click "Save Note"
    Then I should be redirected to the lobby's main page
    And I should see "Note updated successfully"
    When I go to the lobby's note page
    Then I should see "This is the updated note."

  Scenario: Attempting to edit a note as a viewer
    Given the lobby has a note
    And I am logged in as "Viewer Member"
    When I try to go to the edit lobby note page
    Then I should be redirected to the lobby's main page
    And I should see "You are not authorized to edit this note"

  Scenario: Attempting to edit a note as a non-member
    Given the lobby has a note
    And I am logged in as "Other User"
    When I try to go to the edit lobby note page
    Then I should be redirected to the lobby's main page
    And I should see "You are not authorized to edit this note"

  Scenario: Submitting an invalid (blank) note
    Given the lobby has a note with content "Original content"
    And I am logged in as "Editor Member"
    When I go to the edit lobby note page
    And I fill in the note content with ""
    And I click "Save Note"
    Then I should still be on the edit lobby note page
    # Assuming your form re-renders with an error
    And I should see "Content can't be blank"
    When I go to the lobby's note page
    Then I should see "Original content"
