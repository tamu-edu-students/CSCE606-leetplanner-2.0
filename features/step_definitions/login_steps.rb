# This step mocks the Google OAuth response that the application received
Given('a student with the email {string} can be authenticated by Google') do |email|
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
    provider: 'google_oauth2',
    uid: '123545',
    info: { email: email, first_name: 'Test', last_name: 'User' },
    credentials: { token: 'mock_google_token', refresh_token: 'mock_google_refresh_token' }
  })
end

Given('I am logged in as a student') do
  email = 'student@tamu.edu'
  user = User.find_or_create_by!(email: email) do |u|
    u.netid = email.split('@').first
    u.first_name = 'Test'
    u.last_name  = 'Student'
  end
  user.update!(last_login_at: Time.current)

  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
    provider: 'google_oauth2',
    uid: '123545',
    info: { email: email, first_name: user.first_name, last_name: user.last_name },
    credentials: { token: 'mock_google_token', refresh_token: 'mock_google_refresh_token' }
  })
  visit '/auth/google_oauth2/callback'
end

Given('I am on the login page') do
  visit path_for('login')
end

When('I sign in with Google') do
  if page.has_link?('Sign in with Google')
    click_link('Sign in with Google')
  else
    visit '/auth/google_oauth2/callback'
  end
end

Then('I should be redirected to the dashboard') do
  expect(page).to have_current_path(path_for('dashboard'))
end

Then('I should see a confirmation message {string}') do |message|
  expect(page).to have_content(message)
end

Then('I should see a success message {string}') do |message|
  expect(page).to have_selector('.flash-success', text: message)
end

Then('I should see an error message {string}') do |message|
  expect(page).to have_selector('.flash-alert', text: message)
end

Then('I should be redirected to the login page') do
  expect(page).to have_current_path(path_for('login'))
end

Then('I should still be on the login page') do
  expect(page).to have_current_path(path_for('login'))
end
