# Step definitions for authentication and session management features

Given('I am not logged in') do
  if Rails.env.test?
    visit '/test/clear_session'
  else
    # Fallback for non-test environments
    page.driver.browser.clear_cookies if page.driver.respond_to?(:browser)
    visit path_for('login')
  end
end

When('I visit the debug session page') do
  visit '/debug/session'
end

When('I visit the OAuth failure page') do
  visit '/auth/failure'
end

When('I visit the OAuth failure page with message {string}') do |message|
  visit "/auth/failure?message=#{CGI.escape(message)}"
end

When('I visit the logout page') do
  page.driver.submit :delete, '/logout', {}
end

When('I visit a protected page without being logged in') do
  visit '/dashboard'
end

When('I make a JSON request without being logged in to protected endpoint') do
  page.driver.header('Accept', 'application/json')
  page.driver.header('Content-Type', 'application/json')
  visit '/api/current_user'
end

Then('I should be redirected to the root page') do
  expect(current_path).to eq('/')
end

Then('I should see the session data') do
  expect(page.status_code).to eq(200)
end

Then('the page status should be 200') do
  expect(page.status_code).to eq(200)
end

Then('I should receive an unauthorized response') do
  expect(page.status_code).to eq(401)
end

Then('the response should contain {string}') do |text|
  expect(page.body).to include(text)
end
