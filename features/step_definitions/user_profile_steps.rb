When('I click on the profile tab') do
  within('.sidebar-nav') do
    click_link 'Profile'
  end
end

When('I visit my profile page') do
  visit path_for('profile')
end

Then('I should be on the user profile page') do
  expect(page).to have_current_path(path_for('profile'))
end

Then('my {string} should be {string}') do |field, value|
  @current_user.reload
  expect(@current_user.public_send(field.parameterize.underscore)).to eq(value)
end

Given('my first name is {string}') do |name|
  @current_user.update!(first_name: name)
  visit path_for('profile') # Re-visit the page to see the updated value
end

Then('the {string} field should still contain {string}') do |field, value|
  expect(page).to have_field(field, with: value)
end

Then('I should still be on the profile page') do
  expect(page).to have_current_path(path_for('profile'), ignore_query: true)
end
