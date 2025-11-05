Feature: LeetCode Session Problem Management
  As a user scheduling study sessions
  I want to attach problems to a session
  So that my calendar events reflect planned practice

  Background:
    Given I am logged in
    And a leetcode session exists for me
    And a leetcode problem exists titled "Two Sum"

  Scenario: Successfully adding a problem to a session
    When I add the problem to the session
    Then I should see a session add problem success flash

  Scenario: Adding a non-existent problem fails
    When I attempt to add a missing problem id to the session
    Then I should see a session add problem failure flash
