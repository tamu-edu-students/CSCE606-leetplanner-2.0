# Feature: User profile management
# Given: A logged-in user
# When: The user accesses their profile page
# Then: The user can view and update their personal details, and see errors for invalid data.

Feature: User Profile Management
  As a user,
  I want to manage my profile information,
  so that I can keep my account details up to date.

  Background:
    Given I am a logged-in user
    And I am on my profile page

  Scenario: Viewing the user profile page
    Then I should see the profile form
    And I should see my current "first_name"
    And I should see my current "last_name"
    And I should see my current "leetcode_username"

  Scenario: Successfully updating user profile information
    When I fill in "First name" with "John"
    And I fill in "Last name" with "Doe"
    And I fill in "Leetcode username" with "johndoe123"
    And I click the "Update Profile" button
    Then I should see the success message "Profile updated successfully"
    And the "First name" field should contain "John"
    And the "Last name" field should contain "Doe"
    And the "Leetcode username" field should contain "johndoe123"

  Scenario: Failing to update profile with invalid data
    # This scenario tests the error handling path in the UsersController#profile action.
    Given my first name is "Jane"
    When I fill in "First name" with ""
    And I click the "Update Profile" button
    Then I should see an error message "First name can't be blank"
    And the "First name" field should still contain "Jane"
    And I should still be on the profile page

  # --- API Scenarios ---
  @api
  Scenario: Access profile API when authenticated
    When I visit the user profile API endpoint
    Then the response status should be 200
    And the JSON response should contain my user details

  @api
  Scenario: Access profile API when not authenticated
    Given I am not logged in
    When a visitor visits the user profile API endpoint
    Then the response status should be 401
    And the JSON response should contain an error message "Not signed in"