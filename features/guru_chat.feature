Feature: Guru AI Chat
  As a logged in user
  I want to interact with the Guru assistant
  So that I can receive helpful coding guidance

  Background:
    Given I am logged in

  Scenario: Viewing the Guru chat initializes welcome message
    When I visit the guru chat page
    Then I should see "Guru" on the page
    And I should see a guru bot welcome message

  Scenario: Sending a valid guru message produces bot reply
    When I send a guru chat message "Hello Guru"
    Then I should see a guru bot response containing "Hello! How can I assist you today?"

  Scenario: Blank guru message is rejected
    When I attempt to send a blank guru chat message
    Then I should see a guru error flash
