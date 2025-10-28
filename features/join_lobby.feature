Feature: Join Lobby
  As a user, I want to join a lobby using a code
  so that I can participate in a collaborative session.

  Scenario: User joins a lobby with a valid code (Happy Path)
    Given a lobby named "Data Structures Deep Dive" exists
    And I am a registered user named "Charlie" who is not in the lobby
    When I attempt to join the lobby with the correct lobby code
    Then I should be on the page for "Data Structures Deep Dive"
    And I should see my name "Charlie" in the participant list

  Scenario: User fails to join with an invalid code (Sad Path)
    Given a lobby named "Data Structures Deep Dive" exists
    And I am a registered user
    When I attempt to join the lobby with an invalid lobby code
    Then I should see an error message "Invalid lobby code. Please try again."
    And I should be on the lobbies page

  Scenario: User attempts to join a lobby they are already in (Sad Path)
    Given I am a registered user and a member of the "Data Structures Deep Dive" lobby
    When I attempt to join the lobby with the correct lobby code again
    Then I should see an error message "You are already in this lobby."
    And I should be on the lobbies page