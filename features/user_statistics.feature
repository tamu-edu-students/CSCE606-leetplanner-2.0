# Feature: User can view weekly stats report
# Given: User has LeetCode username configured and solved problems
# When: User navigates to statistics page
# Then: User sees personalized progress metrics and achievements

@timecop
Feature: LeetCode Statistics
  As a user tracking my coding skills
  I want to see my LeetCode solved problems count
  So that I can monitor my progress.

  Background:
    Given I am a logged-in user
    And I have a LeetCode username set

  Scenario: Viewing stats with recent activity
    Given I have solved 5 problems this week
    And I have solved 50 problems in total
    And my longest solving streak is 10 days
    And the hardest problem I solved this week was "Median of Two Sorted Arrays (Hard)"
    And I have solved problems on 3 consecutive days this week
    When I navigate to my LeetCode stats page
    Then I should see "Weekly Solved: 5"
    And I should see "Total Solved: 50"
    And I should see "Current Week Streak: 3 days"
    And I should see a highlight for "Longest streak: 10 days"
    And I should see a highlight for "Hardest problem this week: Median of Two Sorted Arrays (hard)"

  Scenario: Viewing stats with no activity this week
    Given I have solved 0 problems this week
    And I have solved 25 problems in total
    When I navigate to my LeetCode stats page
    Then I should see "Weekly Solved: 0"
    And I should see "Total Solved: 25"
    And I should see "Current Week Streak: 0 days"
    And I should not see a "Hardest problem this week" highlight

  Scenario: Viewing stats without a LeetCode username
    Given I have no LeetCode username set
    When I navigate to my LeetCode stats page
    Then I should see a message asking me to set my LeetCode username
    And I should see all statistics as zero