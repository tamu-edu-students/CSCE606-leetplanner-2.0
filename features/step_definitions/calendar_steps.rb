Given('I am a logged-in user and successfully authenticated with Google') do
  page.set_rack_session(google_token: 'mock_google_token', google_refresh_token: 'mock_refresh_token')
end

When('I check the {string} checkbox') do |label|
  check(label, allow_label_click: true)
end

Then('a {string} with the title {string} should exist') do |model_name, title|
  expect(model_name.constantize.find_by(title: title)).not_to be_nil
end

Then('a {string} for the date {string} should exist') do |model_name, date_str|
  date = Date.parse(date_str)
  # Checks if a session exists that starts on the given date
  expect(model_name.constantize.where(scheduled_time: date.all_day)).to exist
end

Given('my Google authentication has expired') do
  allow_any_instance_of(Signet::OAuth2::Client).to receive(:refresh!).and_raise(Signet::AuthorizationError.new('Token expired'))
  
  page.set_rack_session(google_token_expires_at: 1.hour.ago.to_i)
end

Then('I should see the alert {string}') do |message|
  expect(page).to have_selector('.alert', text: message)
end
