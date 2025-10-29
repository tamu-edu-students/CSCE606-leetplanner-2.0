# Feature: User authentication via Google OAuth
# Given: User has valid TAMU email address
# When: User attempts to sign in with Google
# Then: User is authenticated and can access protected features
@javascript
Feature: User Authentication
As a student
I want to log in and out of my account
So that I can securely access my personal information

Scenario: Successful login via Google
Given a student with the email "student@tamu.edu" can be authenticated by Google
And I am on the login page
When I sign in with Google
Then I should be redirected to the dashboard
And I should see a success message "Signed in as student@tamu.edu"

Scenario: User logs out successfully
Given I am logged in as a student
When I click the "Sign Out" button
Then I should be redirected to the login page
And I should see a confirmation message "You have been signed out successfully"
And I should not see a "Sign Out"

Scenario: Failed login with a non-allowed email domain
Given a student with the email "student@example.com" can be authenticated by Google
And I am on the login page
When I sign in with Google
Then I should still be on the login page
And I should see an error message "Login restricted to TAMU emails"