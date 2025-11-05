Feature: Lobby Messages
  As a lobby participant
  I want to send messages in a lobby
  So that I can communicate with other participants

  Background:
    Given I am logged in
    And a lobby exists that I own

  Scenario: Posting a valid message to the lobby
    When I post a lobby message "Hello everyone"
    Then the lobby should have a message "Hello everyone"

  Scenario: Posting an invalid empty message
    When I post an empty lobby message
    Then the lobby should have no new messages
