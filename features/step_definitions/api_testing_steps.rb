# frozen_string_literal: true

# Step definitions for API testing
# Simple, RuboCop-compliant implementation

When('I visit {string}') do |path|
  visit path
end

When('I visit {string} with JSON headers') do |path|
  page.driver.header('Accept', 'application/json')
  visit path
end

When('I visit the home page') do
  visit root_path
end

When('I visit the about page') do
  visit root_path # Assuming about info is on home page
end

Then('the response should be successful') do
  expect(page.status_code).to be_between(200, 299)
end

Then('the response should contain user data in JSON format') do
  expect(page.response_headers['Content-Type']).to include('application/json')
end

Then('the page should load successfully') do
  expect(page.status_code).to eq(200)
end

Then('I should see application information') do
  expect(page).to have_content('Leet Planner')
end

Then('I should see helpful links') do
  expect(page).to have_css('a[href]')
end
