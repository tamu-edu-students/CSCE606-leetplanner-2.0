# This step mocks the Google OAuth response that the application received
# It is used for both successful and failed login scenarios
Given('a student with the email {string} can be authenticated by Google') do |email|
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
    provider: 'google_oauth2',
    uid: '123545',
    info: {
      email: email,
      first_name: 'Test',
      last_name: 'User'
    },
    credentials: {
      token: 'mock_google_token',
      refresh_token: 'mock_google_refresh_token'
    }
  })
end

Given('I am logged in as a student') do
  # Ensure a user exists and perform the OmniAuth callback so the test is
  # authenticated (works for both rack_test and JS drivers)
  email = 'student@tamu.edu'

  user = User.find_or_initialize_by(email: email)
  user.netid ||= email.split('@').first
  user.first_name ||= 'Test'
  user.last_name  ||= 'Student'
  user.last_login_at = Time.current
  user.save! if user.changed?

  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
    provider: 'google_oauth2',
    uid: '123545',
    info: { email: email, first_name: user.first_name, last_name: user.last_name },
    credentials: { token: 'mock_google_token', refresh_token: 'mock_google_refresh_token' }
  })

  visit '/auth/google_oauth2/callback'
  expect(page).to have_current_path(path_for('dashboard'))
end

# Navigates to the root/login page using the path helper
Given('I am on the login page') do
  visit path_for('login')
end

# Simulates clicking the "Sign in with Google" button and handles redirection
When('I sign in with Google') do
  # Try to click the real sign-in link if present, otherwise hit the callback
  if page.has_link?('Sign in with Google')
    click_link('Sign in with Google')
    # If the link click did not reach the callback
    # explicitly visit the callback to complete the mocked OAuth flow.
    visit '/auth/google_oauth2/callback' unless page.current_path == path_for('dashboard')
  else
    visit '/auth/google_oauth2/callback'
  end
end

# Verifies redirection to the dashboard after a successful login
Then('I should be redirected to the dashboard') do
  expect(page).to have_current_path(path_for('dashboard'))
end

# This step is for the successful logout message
Then('I should see a confirmation message {string}') do |message|
  expect(page).to have_content(message)
end

Then('I should see a success message {string}') do |message|
  expect(page).to have_content(message)
end

Then('I should see an error message {string}') do |message|
  expect(page).to have_content(message)
end

# Verifies that after logging out or a failed login, the user is on the login page
Then('I should be redirected to the login page') do
  expect(page).to have_current_path(path_for('login'))
end

# Verifies that after a failed login attempt, the user remains on the login page
Then('I should still be on the login page') do
  expect(page).to have_current_path(path_for('login'))
end
