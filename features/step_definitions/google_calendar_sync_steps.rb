require "google/apis/calendar_v3"

Given("a user exists with valid Google credentials") do
  @user = User.find_or_create_by!(netid: "test123") do |u|
    u.email = "test@test.com"
    u.first_name = "Test"
    u.last_name = "User"
    u.role = "student"
    u.active = true
  end

  @session = {
    google_token: "valid-token",
    google_refresh_token: "valid-refresh-token",
    google_token_expires_at: 1.hour.from_now
  }

  # Mock OAuth client
  allow(Signet::OAuth2::Client).to receive(:new).and_return(double(expired?: false))

  # Mock Google Calendar service
  @mock_service = double("GoogleCalendarService")
  allow(@mock_service).to receive(:authorization=)

  # Mock successful API call
  mock_event = double(
    "GoogleEvent",
    id: "1",
    status: "confirmed",
    start: double(date_time: Time.now),
    end: double(date_time: 1.hour.from_now),
    summary: "Mock Event",
    description: "Mock Description"
  )
  response = double(items: [ mock_event ])
  allow(@mock_service).to receive(:list_events).and_return(response)

  allow(LeetCodeSession).to receive(:find_or_initialize_by).and_return(LeetCodeSession.new(user: @user))
  allow(Google::Apis::CalendarV3::CalendarService).to receive(:new).and_return(@mock_service)
end

Given("the user has invalid Google credentials") do
  @user = User.find_or_create_by!(netid: "invalid123") do |u|
    u.email = "invalid@test.com"
    u.first_name = "Invalid"
    u.last_name = "User"
    u.role = "student"
    u.active = true
  end

  @session = {} # No valid token
  allow(Signet::OAuth2::Client).to receive(:new).and_return(double(expired?: true))
end

Given("the Google Calendar API raises an error") do
  step "a user exists with valid Google credentials"
  allow(@mock_service).to receive(:list_events).and_raise(Google::Apis::Error.new("API failure"))
end

Given("an unexpected error occurs during sync") do
  step "a user exists with valid Google credentials"
  allow(@mock_service).to receive(:list_events).and_raise(StandardError.new("Unexpected failure"))
end

When("the user performs a calendar sync") do
  @result = GoogleCalendarSync.new(@user).sync(@session)
end

Then("the sync result should indicate success") do
  expect(@result[:success]).to eq(true)
end

Then("the sync result should include sync statistics") do
  expect(@result).to include(:synced, :updated, :skipped, :deleted)
end

Then("the sync result should indicate failure") do
  expect(@result[:success]).to eq(false)
end

Then("the error message should be {string}") do |message|
  expect(@result[:error]).to eq(message)
end

Then("the error message should contain {string}") do |substring|
  expect(@result[:error]).to include(substring)
end

When("I call the class method sync_for_user for the user") do
  @result = GoogleCalendarSync.sync_for_user(@user, @session)
end

Given("the Google token is expired") do
  # Mock an OAuth client with an expired token
  oauth_double = double(
    expired?: true
  )

  # Simulate a failed refresh by raising Signet::AuthorizationError
  allow(oauth_double).to receive(:refresh!).and_raise(Signet::AuthorizationError.new("Token expired"))

  allow(oauth_double).to receive(:access_token).and_return(nil)
  allow(oauth_double).to receive(:refresh_token).and_return(nil)
  allow(oauth_double).to receive(:expires_at).and_return(nil)

  allow(Signet::OAuth2::Client).to receive(:new).and_return(oauth_double)
end




Given("the Google Calendar API returns an event that fails to sync") do
  step "a user exists with valid Google credentials"

  # Mock a sync failure for a specific event
  mock_event = double("GoogleEvent",
                      id: "fail_event",
                      status: "confirmed",
                      start: double(date_time: Time.now + 1.hour),
                      end: double(date_time: Time.now + 2.hours),
                      summary: "Fail Event",
                      description: "This event will fail")

  response = double(items: [ mock_event ])
  allow(@mock_service).to receive(:list_events).and_return(response)

  # Force LeetCodeSession#create_or_update to raise an error for this event
  allow(LeetCodeSession).to receive(:find_or_initialize_by).and_raise(StandardError.new("Sync failed"))
end



Then("the synced, updated, skipped, and deleted counts should be present") do
  expect(@result).to include(:synced, :updated, :skipped, :deleted)
end

Given("the Google Calendar API returns a past event") do
  step "a user exists with valid Google credentials"

  past_time = 2.hours.ago
  mock_event = double(
    "GoogleEvent",
    id: "3",
    status: "confirmed",
    start: double(date_time: past_time - 1.hour),
    end: double(date_time: past_time),
    summary: "Past Event",
    description: "Already ended"
  )
  response = double(items: [ mock_event ])
  allow(@mock_service).to receive(:list_events).and_return(response)
  allow_any_instance_of(GoogleCalendarSync).to receive(:sync_event).and_call_original
end

Then("the event should be considered completed") do
  expect(@result[:synced]).to eq(1) # Because the past event still counts as synced
end

Given("the Google Calendar API returns an existing event that should be updated") do
  step "a user exists with valid Google credentials"

  # Create an existing session for the user
  existing_session = LeetCodeSession.create!(
    user: @user,
    google_event_id: "update_event",
    summary: "Old Summary"
  )

  mock_event = double("GoogleEvent",
                      id: "update_event",
                      status: "confirmed",
                      start: double(date_time: Time.now + 1.hour),
                      end: double(date_time: Time.now + 2.hours),
                      summary: "Updated Summary",
                      description: "Updated description")

  response = double(items: [ mock_event ])
  allow(@mock_service).to receive(:list_events).and_return(response)

  # Return the existing session so it will be updated
  allow(LeetCodeSession).to receive(:find_or_initialize_by).and_return(existing_session)
end


Given("the Google token is valid but needs refresh") do
  step "a user exists with valid Google credentials"

  oauth_double = double(
    expired?: true,
    access_token: "new-access-token",
    refresh_token: "new-refresh-token",
    expires_at: 1.hour.from_now
  )

  # Mock a successful refresh
  allow(oauth_double).to receive(:refresh!).and_return(true)
  allow(Signet::OAuth2::Client).to receive(:new).and_return(oauth_double)
end

Given("the Google token is expired but refresh succeeds") do
  step "a user exists with valid Google credentials"

  oauth_double = double(
    expired?: true,
    access_token: "new-access-token",
    refresh_token: "new-refresh-token",
    expires_at: 1.hour.from_now
  )

  # Mock successful refresh
  allow(oauth_double).to receive(:refresh!).and_return(true)
  allow(Signet::OAuth2::Client).to receive(:new).and_return(oauth_double)
end

Given("the Google Calendar API returns an event that cannot be synced") do
  step "a user exists with valid Google credentials"

  # Mock an event from Google
  mock_event = double(
    "GoogleEvent",
    id: "fail_event",
    status: "confirmed",
    start: double(date_time: Time.now + 1.hour),
    end: double(date_time: Time.now + 2.hours),
    summary: "Fail Event",
    description: "This event will fail"
  )

  response = double(items: [ mock_event ])
  allow(@mock_service).to receive(:list_events).and_return(response)

  # Force LeetCodeSession sync to fail
  allow(LeetCodeSession).to receive(:find_or_initialize_by).and_raise(StandardError.new("Sync failed"))
end

Given("the Google Calendar API returns an event that does not change") do
  step "a user exists with valid Google credentials"

  # Create an existing session that matches the Google event exactly
  existing_session = LeetCodeSession.create!(
    user: @user,
    google_event_id: "event-skipped",
    status: :scheduled
  )

  # Mock a Google event with the same details
  mock_event = double(
    "GoogleEvent",
    id: "event-skipped",
    status: "confirmed",
    start: double(date_time: Time.now + 1.hour),
    end: double(date_time: Time.now + 2.hours),
    summary: "Scheduled Event",
    description: "Scheduled Event"
  )

  response = double(items: [ mock_event ])
  allow(@mock_service).to receive(:list_events).and_return(response)

  # Force sync_event to return :skipped for this exact event
  allow_any_instance_of(GoogleCalendarSync).to receive(:sync_event).with(mock_event).and_return(:skipped)
end

Given("the Google Calendar API returns an event that has been updated") do
  step "a user exists with valid Google credentials"

  # Existing session in DB
  existing_session = LeetCodeSession.create!(
    user: @user,
    google_event_id: "event456",
    status: :scheduled
  )

  # Mock Google event with same ID but different details
  mock_event = double(
    "GoogleEvent",
    id: "event456",
    status: "confirmed",
    start: double(date_time: Time.now + 2.hours),
    end: double(date_time: Time.now + 3.hours),
    summary: "Updated Event",
    description: "Event description changed"
  )

  response = double(items: [ mock_event ])
  allow(@mock_service).to receive(:list_events).and_return(response)

  # Mock find_or_initialize to return our existing session
  allow(LeetCodeSession).to receive(:find_or_initialize_by).with(user: @user, google_event_id: "event456").and_return(existing_session)

  # Simulate that saving updates the session and triggers :updated
  allow(existing_session).to receive(:previous_changes).and_return({ summary: [ "Old Event", "Updated Event" ] })
end


Given("the Google Calendar API returns an event that triggers an update") do
  step "a user exists with valid Google credentials"

  # Existing session
  existing_session = LeetCodeSession.create!(
    user: @user,
    google_event_id: "event123",
    status: :scheduled
  )

  # Mock Google event with the same ID but updated details
  mock_event = double(
    "GoogleEvent",
    id: "event123",
    status: "confirmed",
    start: double(date_time: Time.now + 1.hour),
    end: double(date_time: Time.now + 2.hours),
    summary: "Updated Event",
    description: "New description"
  )

  response = double(items: [ mock_event ])
  allow(@mock_service).to receive(:list_events).and_return(response)

  # Force sync_event to return :updated for this event
  allow_any_instance_of(GoogleCalendarSync).to receive(:sync_event).with(mock_event).and_return(:updated)
end
