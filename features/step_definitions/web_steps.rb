When('I click the {string} button') do |button_text|
  click_link_or_button(button_text)
end

When('I press {string}') do |link_or_button_text|
  begin
    click_link(link_or_button_text)
  rescue Capybara::ElementNotFound
    click_button(link_or_button_text)
  end
end

When('I fill in {string} with {string}') do |field, value|
  fill_in(field, with: value)
end

Then('I should see {string}') do |text|
  expect(page).to have_content(text)
end

Then('I should not see a {string}') do |text|
  expect(page).not_to have_content(text)
end
