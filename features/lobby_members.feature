Feature: View Participant List
  As a lobby participant, I want to see a list of everyone present
  so I know who I am collaborating with.

  Scenario: Participant sees a list of all users in the lobby (Happy Path)
    Given a lobby exists with owner "Alice" and participant "Bob"
    And I am logged in as "Alice" and am viewing the lobby
    Then I should see "Alice" in the list
    And I should see "Bob" in the list