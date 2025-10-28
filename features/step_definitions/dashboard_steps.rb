# --- GIVEN STEPS (Setup) ---

Given('my Google Calendar has no ongoing events') do
  allow_any_instance_of(Google::Apis::CalendarV3::CalendarService).to receive(:list_events).and_return(
    instance_double(Google::Apis::CalendarV3::Events, items: [])
  )
end

Given('I have no active manual timer') do
  # A test-only route is the most reliable way to clear session state.
  visit '/test/clear_timer' if Rails.env.test?
end

Given('my Google Calendar has an ongoing event {string} ending in 30 minutes') do |event_title|
  event = Google::Apis::CalendarV3::Event.new(
    summary: event_title,
    start: Google::Apis::CalendarV3::EventDateTime.new(date_time: Time.current - 1.hour),
    'end': Google::Apis::CalendarV3::EventDateTime.new(date_time: Time.current + 30.minutes)
  )
  allow_any_instance_of(Google::Apis::CalendarV3::CalendarService).to receive(:list_events).and_return(
    instance_double(Google::Apis::CalendarV3::Events, items: [event])
  )
end

Given('my Google Calendar has an ongoing all-day event {string}') do |event_title|
  today = Date.today
  event = Google::Apis::CalendarV3::Event.new(
    summary: event_title,
    start: Google::Apis::CalendarV3::EventDateTime.new(date: today.to_s),
    'end': Google::Apis::CalendarV3::EventDateTime.new(date: (today + 1.day).to_s)
  )
  allow_any_instance_of(Google::Apis::CalendarV3::CalendarService).to receive(:list_events).and_return(
    instance_double(Google::Apis::CalendarV3::Events, items: [event])
  )
end

Given('my Google Calendar has an event {string} that just ended') do |event_title|
  event = Google::Apis::CalendarV3::Event.new(
    summary: event_title,
    start: Google::Apis::CalendarV3::EventDateTime.new(date_time: Time.current - 1.hour),
    'end': Google::Apis::CalendarV3::EventDateTime.new(date_time: Time.current - 1.minute)
  )
  allow_any_instance_of(Google::Apis::CalendarV3::CalendarService).to receive(:list_events).and_return(
    instance_double(Google::Apis::CalendarV3::Events, items: [event])
  )
end

Given('I have a manual timer that expired 5 minutes ago') do
  expired_time = (Time.current - 5.minutes).iso8601
  page.set_rack_session(timer_ends_at: expired_time, google_token: 'fake-token')

  # ADD THIS LINE: This prevents the API call from failing.
  allow_any_instance_of(Google::Apis::CalendarV3::CalendarService).to receive(:list_events).and_return(
    instance_double(Google::Apis::CalendarV3::Events, items: [])
  )
end

Given('the Google Calendar API is unavailable') do
  allow_any_instance_of(Google::Apis::CalendarV3::CalendarService)
    .to receive(:list_events)
    .and_raise(Google::Apis::ServerError.new('Backend Error'))
end

# --- WHEN STEPS (Actions) ---

When('I visit the dashboard page') do
  visit dashboard_path
end

When('I create a manual timer for {string} minutes') do |minutes|
  # This uses the non-JS form for reliability in tests.
  within('noscript form') do
    fill_in 'minutes', with: minutes
    click_button 'Start'
  end
end

# --- THEN STEPS (Assertions) ---

Then('I should see the timer display showing {string}') do |time|
  within('#timerDisplay') do
    expect(page).to have_content(time)
  end
end

Then('I should not see a current event banner') do
  expect(page).not_to have_selector('.event-banner')
end

Then('I should see the current event title {string}') do |event_title|
  within('.event-banner') do
    expect(page).to have_selector('h2.event-title', text: "Now: #{event_title}")
  end
end

Then('I should see a countdown timer with approximately {string} remaining') do |time_string|
  parts = time_string.split(':').map(&:to_i)
  expected_seconds = parts[0] * 3600 + parts[1] * 60 + parts[2]

  within('#timerDisplay') do
    displayed_time_str = first(:xpath, '.').text.split("\n").first
    displayed_seconds = displayed_time_str.split(':').map(&:to_i).inject(0) { |a, b| a * 60 + b }
    expect(displayed_seconds).to be_within(2).of(expected_seconds)
  end
end

Then('I should see a countdown timer showing the time until midnight') do
  expected_seconds = (Time.current.end_of_day - Time.current).to_i

  within('#timerDisplay') do
    displayed_time_str = first(:xpath, '.').text.split("\n").first
    displayed_seconds = displayed_time_str.split(':').map(&:to_i).inject(0) { |a, b| a * 60 + b }
    expect(displayed_seconds).to be_within(2).of(expected_seconds)
  end
end

Then('the timer should be cleared from my session') do
  expect(page.get_rack_session['timer_ends_at']).to be_nil
end

Then('I should see a calendar sync error message') do
  expect(page).to have_selector('.flash-alert', text: 'Unable to sync with Google Calendar')
end
