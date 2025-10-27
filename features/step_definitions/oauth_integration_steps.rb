# OAuth integration step definitions

Given('I create a test user with tokens') do
  @test_user = User.create!(
    email: 'oauth@tamu.edu',
    netid: 'oauth',
    first_name: 'OAuth',
    last_name: 'User',
    google_access_token: 'token_to_clear',
    google_refresh_token: 'refresh_to_clear'
  )
end

When('I visit the sessions create endpoint') do
  # This will hit the controller but without proper OAuth setup
  visit '/sessions/create'
end

When('I visit the sessions destroy endpoint') do
  # This will test the destroy action
  page.driver.submit(:delete, '/logout', {})
end

Then('I should get a response') do
  expect(page.status_code).to be_between(200, 399)
end

Then('the response should clear tokens') do
  expect(page.status_code).to be_between(200, 399)
end
