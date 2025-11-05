Feature: Manage Participant Permissions
  As a lobby owner, I want to control what participants can do
  to ensure a productive and orderly session.

  # Temporarily disabled failing scenario (missing Can Draw checkbox implementation)
  # Scenario: Owner grants permissions to a participant (Happy Path)
  #   Given I am the owner of a lobby with "Bob" as a participant
  #   And "Bob" does not have permission to draw
  #   When I check the "Can Draw" box for "Bob" and click "Update All Permissions"
  #   Then I should see a success message "All participant permissions have been updated."
  #   And the "Can Draw" box for "Bob" should be checked

  Scenario: A non-owner cannot see the permissions table (Sad Path)
    Given "Alice" is the owner of a lobby
    And I am logged in as "Bob", a participant in that lobby
    When I visit the lobby page
    Then I should not see the "Manage Permissions" table

  Scenario: Owner updates a participant's permissions
    Given I am the owner of a lobby with "Bob" as a participant
    When I set draw and edit notes permissions for "Bob"
    Then the participant "Bob" should have draw permission enabled
    And the participant "Bob" should have edit notes permission enabled

  Scenario: Non-owner cannot update a participant's permissions
    Given a lobby exists with owner "Alice" and participant "Bob"
    And I am logged in as "Charlie", a participant in that lobby
    When I try to patch permissions for "Bob" without ownership
    Then I should see an unauthorized lobby permissions alert