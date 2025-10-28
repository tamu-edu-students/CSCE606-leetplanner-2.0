Feature: Leave Lobby
  As a participant, I want to leave a lobby I am currently in.

  Scenario: A participant successfully leaves a lobby (Happy Path)
    Given I am logged in as "Bob" and am in a lobby
    When I click the "Leave Lobby" button
    Then I should be redirected to the lobbies page
    And I should see a success message "You have left the lobby."