# This step mocks the Google OAuth response that your application will receive.
# It is used for both successful and failed login scenarios.
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
  expect(page).to have_current_path(path_for('dashboard'))
end

# Navigates to the root/login page using your path helper.
Given('I am on the login page') do
  visit path_for('login')
end

# Verifies redirection to the dashboard after a successful login.
Then('I should be redirected to the dashboard') do
  expect(page).to have_current_path(path_for('dashboard'))
end

# This step is for the successful logout message.
Then('I should see a confirmation message {string}') do |message|
  expect(page).to have_content(message)
end

# Verifies that after logging out or a failed login, the user is on the login page.
Then('I should be redirected to the login page') do
  expect(page).to have_current_path(path_for('login'))
end

# Verifies that after a failed login attempt, the user remains on the login page.
Then('I should still be on the login page') do
  expect(page).to have_current_path(path_for('login'))
end
