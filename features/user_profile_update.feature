Feature: User Profile Management

  Background:
    Given I am a logged-in user and successfully authenticated with Google

  Scenario: Successfully updating user profile
    Given I am on the profile page
    When I update my profile with:
      | first_name | John              |
      | last_name  | Doe               |
      | leetcode_username | leetcoder123 |
    Then I should see "Profile updated successfully"
    And my profile should show the updated information

  Scenario: Handling invalid profile updates
    Given I am on the profile page
    When I update my profile with:
      | first_name |                   |
      | last_name  | Doe               |
    Then I should see "First name can't be blank"
    And my profile should retain the previous values

  Scenario: JSON response for profile update
    Given I send a JSON profile update request with:
      | first_name | Jane              |
      | last_name  | Doe               |
    When the server processes the request
    Then I should receive a JSON success response
    And the response should include the updated user data