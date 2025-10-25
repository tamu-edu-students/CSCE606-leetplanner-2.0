Given('I have no ongoing events in my Google Calendar') do
  allow_any_instance_of(Google::Apis::CalendarV3::CalendarService).to receive(:list_events).and_return(
    instance_double(Google::Apis::CalendarV3::Events, items: [])
  )
end

Given('I have not started a manual timer') do
  page.set_rack_session(timer_ends_at: nil)
end

Given('I have an ongoing event {string} in my Google Calendar ending in 30 minutes') do |event_title|
  event = Google::Apis::CalendarV3::Event.new(
    summary: event_title,
    start: Google::Apis::CalendarV3::EventDateTime.new(date_time: Time.current - 1.hour),
    'end': Google::Apis::CalendarV3::EventDateTime.new(date_time: Time.current + 30.minutes)
  )
  allow_any_instance_of(Google::Apis::CalendarV3::CalendarService).to receive(:list_events).and_return(
    instance_double(Google::Apis::CalendarV3::Events, items: [event])
  )
end

# Step to check for the main page title
Then('I should see the dashboard title') do
  within('#dashboardPage') do
    expect(page).to have_selector('h1.page-title', text: 'Dashboard')
  end
end

# Step to verify the manual timer form is visible when no event is active
Then('I should see the manual timer form') do
  expect(page).to have_content('Focus Timer')
  expect(page).to have_selector('#customTimerInput')
end

# Step to verify the event banner is NOT visible
Then('I should not see a current event banner') do
  expect(page).not_to have_selector('.event-banner')
end

# Step to check the timer display, which is always present
Then('the timer display should show {string}') do |time|
  within('#timerDisplay') do # 
    expect(page).to have_content(time)
  end
end

# Step to find the event title within the event banner
Then('I should see the current event title {string}') do |event_title|
  within('.event-banner') do # 
    expect(page).to have_selector('h2.event-title', text: "Now: #{event_title}")
  end
end

# Step to check the timer display for an approximate time
Then('I should see a countdown timer with approximately {string} remaining') do |time_string|
  # This regex checks for a time close to the expected value, allowing for minor delays in test execution
  minutes = time_string.split(':')[1].to_i
  regex = /00:(#{minutes}|#{minutes - 1}):\d{2}/
  
  within('#timerDisplay') do
    expect(page).to have_text(regex)
  end
end

# Step to create a timer using the specific input field ID
When('I create a manual timer for {string} minutes') do |minutes|
  # The view uses a JS controller, so we target the visible input and button
  fill_in 'customTimerInput', with: minutes
  find('button.btn.set.js-only', text: 'Start').click
end
