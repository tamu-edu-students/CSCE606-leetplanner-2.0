Feature: Weekly Statistics Report Logic
  As a user, I want to see detailed and accurate weekly stats,
  including streaks and highlights for my achievements.

  Background:
    Given I am a logged-in user

  Scenario: Calculating a multi-day streak
    Given I solved a problem on Monday of this week
    And I solved a problem on Tuesday of this week
    When I visit the statistics page
    Then I should see a "Current Week Streak" of "2 days"

  Scenario: Handling a broken streak
    Given I solved a problem on Monday of this week
    And I solved a problem on Wednesday of this week
    When I visit the statistics page
    Then I should see a "Current Week Streak" of "1 day"

  Scenario: Highlighting the hardest problem of the week
    Given I solved an "Easy" problem titled "Two Sum" this week
    And I solved a "Hard" problem titled "Trapping Rain Water" this week
    When I visit the statistics page
    Then I should see the highlight "Trapping Rain Water (hard)"

  Scenario: Highlighting the historical longest streak
    Given my historical longest streak is 15 days
    And I solved a problem on Tuesday of this week
    When I visit the statistics page
    Then I should see the highlight "Longest streak: 15 days"