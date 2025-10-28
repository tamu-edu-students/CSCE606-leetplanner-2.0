Given('a student with the email {string} can be authenticated by Google') do |email|
  # This mocks the data that Google would send back after a successful login.
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
    provider: 'google_oauth2',
    uid: '123545',
    info: {
      email: email,
      first_name: 'Test',
      last_name: 'User'
    },
    credentials: {
      token: 'mock_token',
      refresh_token: 'mock_refresh_token'
    }
  })
end

# This step establishes a logged-in state
Given('I am logged in as a student') do
step %(a student with the email "testuser@tamu.edu" can be authenticated by Google)
  visit root_path
  login_element = find(:link_or_button, 'Sign in with Google')
  execute_script("arguments[0].click();", login_element)

  expect(page).to have_current_path(dashboard_path)
end

Given('I am on the login page') do
  visit root_path
end

Then('I should be redirected to the login page') do
  expect(page).to have_current_path(root_path)
end

When('I click {string}') do |link_or_button_text|
  click_link_or_button(link_or_button_text)
end

Then('I should be redirected to the dashboard') do
  expect(page).to have_current_path(dashboard_path)
end

Then('I should still be on the login page') do
  expect(page).to have_current_path(root_path)
end
