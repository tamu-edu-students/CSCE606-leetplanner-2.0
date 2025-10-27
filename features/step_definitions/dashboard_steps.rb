# frozen_string_literal: true

# Step definitions for dashboard functionality testing
# Follows RuboCop standards with minimal, concise implementation

When('I visit the dashboard page') do
  visit dashboard_path
end

Then('the page should load without errors') do
  expect(page.status_code).to eq(200)
end

Then('I should see navigation elements') do
  expect(page).to have_css('nav, .navbar, .navigation')
end
