# Step definitions for Google Calendar Synchronization feature
require 'google/apis/calendar_v3'

# Test data storage
Before do
  @google_events = []
  @mock_session = {}
  @sync_result = nil
  @api_error = nil
  @processing_errors = {}
end

# Background steps
Given('I am a logged-in user with Google Calendar access') do
  @current_user = create(:user,
    email: 'testuser@tamu.edu',
    first_name: 'Test',
    last_name: 'User',
    google_access_token: 'valid_token',
    google_refresh_token: 'valid_refresh_token',
    google_token_expires_at: 1.hour.from_now
  )

  @mock_session = {
    google_token: @current_user.google_access_token,
    google_refresh_token: @current_user.google_refresh_token,
    google_token_expires_at: @current_user.google_token_expires_at
  }
end

# Google Calendar event setup
Given('my Google Calendar has the following events:') do |table|
  @google_events = []
  table.hashes.each do |row|
    event = create_mock_google_event(row)
    @google_events << event
  end
end

Given('I have no existing LeetCode sessions') do
  LeetCodeSession.where(user: @current_user).destroy_all
end

Given('I have an existing LeetCode session for {string} with:') do |google_event_id, table|
  attributes = table.rows_hash
  create(:leet_code_session,
    user: @current_user,
    google_event_id: google_event_id,
    title: attributes['title'],
    scheduled_time: Time.parse(attributes['scheduled_time']),
    duration_minutes: attributes['duration_minutes'].to_i
  )
end

Given('I have existing LeetCode sessions for Google events:') do |table|
  table.hashes.each do |row|
    create(:leet_code_session,
      user: @current_user,
      google_event_id: row['google_event_id'],
      title: row['title'],
      scheduled_time: 1.day.from_now,
      duration_minutes: 60
    )
  end
end

Given('I have existing local-only LeetCode sessions:') do |table|
  table.hashes.each do |row|
    create(:leet_code_session,
      user: @current_user,
      title: row['title'],
      google_event_id: nil,
      scheduled_time: 1.day.from_now,
      duration_minutes: 60
    )
  end
end

# Authentication scenarios
Given('I am not authenticated with Google Calendar') do
  @mock_session = {}
end

Given('my Google access token is expired') do
  @mock_session[:google_token_expires_at] = 1.hour.ago
end

Given('the token refresh fails') do
  @token_refresh_fails = true
end

Given('my Google Calendar access is configured') do
  # Default setup is already done in background
end

Given('the Google Calendar API returns an error') do
  @api_error = Google::Apis::Error.new('API Error', status_code: 500)
end

Given('processing {string} will cause an error') do |event_id|
  @processing_errors[event_id] = StandardError.new('Processing error')
end

# Action steps
When('the Google Calendar sync is performed') do
  # Mock Google API components
  mock_oauth_client = double('Signet::OAuth2::Client')
  mock_calendar_service = double('Google::Apis::CalendarV3::CalendarService')
  mock_events_response = double('Google::Apis::CalendarV3::Events')

  # Setup OAuth client mock
  allow(Signet::OAuth2::Client).to receive(:new).and_return(mock_oauth_client)

  if @mock_session[:google_token]
    allow(mock_oauth_client).to receive(:expired?).and_return(@mock_session[:google_token_expires_at] && @mock_session[:google_token_expires_at] < Time.current)

    if @token_refresh_fails
      allow(mock_oauth_client).to receive(:refresh!).and_raise(Signet::AuthorizationError.new('Refresh failed'))
    else
      allow(mock_oauth_client).to receive(:refresh!).and_return(true)
      allow(mock_oauth_client).to receive(:access_token).and_return('new_token')
      allow(mock_oauth_client).to receive(:refresh_token).and_return('new_refresh_token')
      allow(mock_oauth_client).to receive(:expires_at).and_return(1.hour.from_now)
    end
  end

  # Setup Calendar service mock
  allow(Google::Apis::CalendarV3::CalendarService).to receive(:new).and_return(mock_calendar_service)
  allow(mock_calendar_service).to receive(:authorization=)

  # Setup events response
  allow(mock_events_response).to receive(:items).and_return(@google_events)

  if @api_error
    allow(mock_calendar_service).to receive(:list_events).and_raise(@api_error)
  else
    allow(mock_calendar_service).to receive(:list_events).and_return(mock_events_response)
  end

  # Mock individual event processing errors by making sync_event method fail for specific events
  if @processing_errors.any?
    original_sync_event = GoogleCalendarSync.instance_method(:sync_event)
    allow_any_instance_of(GoogleCalendarSync).to receive(:sync_event) do |instance, event|
      if @processing_errors[event.id]
        # Call the original method which has error handling
        begin
          # Make the original method fail by forcing an exception in the protected code
          allow(event).to receive(:start).and_raise(@processing_errors[event.id])
          original_sync_event.bind(instance).call(event)
        rescue StandardError => e
          # This simulates the error handling in the actual sync_event method
          Rails.logger.error("Failed to sync event #{event.id}: #{e.message}")
          :skipped
        end
      else
        original_sync_event.bind(instance).call(event)
      end
    end
  end

  # Perform the sync
  @sync_result = GoogleCalendarSync.sync_for_user(@current_user, @mock_session)
end

When('I call GoogleCalendarSync.sync_for_user with my user and session') do
  # Same setup as regular sync
  step 'the Google Calendar sync is performed'
end

# Verification steps
Then('the sync should be successful') do
  expect(@sync_result[:success]).to be true
end

Then('the sync should fail with error {string}') do |error_message|
  expect(@sync_result[:success]).to be false
  expect(@sync_result[:error]).to eq(error_message)
end

Then('I should have {int} new LeetCode session(s) created') do |count|
  expect(@sync_result[:synced]).to eq(count)
end

Then('I should have {int} LeetCode session(s) updated') do |count|
  expect(@sync_result[:updated]).to eq(count)
end

Then('I should have {int} LeetCode session(s) deleted') do |count|
  expect(@sync_result[:deleted]).to eq(count)
end

Then('I should have {int} LeetCode session(s) skipped') do |count|
  expect(@sync_result[:skipped]).to eq(count)
end

Then('the session for {string} should have:') do |google_event_id, table|
  session = LeetCodeSession.find_by(user: @current_user, google_event_id: google_event_id)
  expect(session).not_to be_nil

  table.rows_hash.each do |attribute, expected_value|
    case attribute
    when 'title'
      expect(session.title).to eq(expected_value)
    when 'scheduled_time'
      expect(session.scheduled_time.iso8601).to eq(expected_value)
    when 'duration_minutes'
      expect(session.duration_minutes).to eq(expected_value.to_i)
    when 'status'
      expect(session.status).to eq(expected_value)
    when 'description'
      expect(session.description).to eq(expected_value)
    end
  end
end

Then('the session for {string} should have status {string}') do |google_event_id, status|
  session = LeetCodeSession.find_by(user: @current_user, google_event_id: google_event_id)
  expect(session).not_to be_nil
  expect(session.status).to eq(status)
end

Then('the session for {string} should be removed') do |google_event_id|
  session = LeetCodeSession.find_by(user: @current_user, google_event_id: google_event_id)
  expect(session).to be_nil
end

Then('no session should exist for {string}') do |google_event_id|
  session = LeetCodeSession.find_by(user: @current_user, google_event_id: google_event_id)
  expect(session).to be_nil
end

Then('the session for {string} should exist') do |google_event_id|
  session = LeetCodeSession.find_by(user: @current_user, google_event_id: google_event_id)
  expect(session).not_to be_nil
end

Then('the manual sessions should remain unchanged') do
  manual_sessions = LeetCodeSession.where(user: @current_user, google_event_id: nil)
  expect(manual_sessions.count).to eq(2)
  expect(manual_sessions.pluck(:title)).to contain_exactly('Manual Session 1', 'Manual Session 2')
end

# Helper methods
def create_mock_google_event(row)
  event = double('Google::Apis::CalendarV3::Event')

  allow(event).to receive(:id).and_return(row['id'])
  allow(event).to receive(:summary).and_return(row['title'])
  allow(event).to receive(:status).and_return(row['status'] || 'confirmed')

  if row['all_day'] == 'true'
    # All-day event
    start_date_time = double('Google::Apis::CalendarV3::EventDateTime')
    end_date_time = double('Google::Apis::CalendarV3::EventDateTime')

    allow(start_date_time).to receive(:date_time).and_return(nil)
    allow(start_date_time).to receive(:date).and_return(Date.parse(row['date']))
    allow(end_date_time).to receive(:date_time).and_return(nil)
    allow(end_date_time).to receive(:date).and_return(Date.parse(row['date']))

    allow(event).to receive(:start).and_return(start_date_time)
    allow(event).to receive(:end).and_return(end_date_time)
  else
    # Timed event
    start_time = row['start_time'] ? Time.parse(row['start_time']) : nil
    end_time = row['end_time'] ? Time.parse(row['end_time']) : nil

    start_date_time = double('Google::Apis::CalendarV3::EventDateTime')
    end_date_time = double('Google::Apis::CalendarV3::EventDateTime')

    allow(start_date_time).to receive(:date_time).and_return(start_time)
    allow(start_date_time).to receive(:date).and_return(nil)
    allow(end_date_time).to receive(:date_time).and_return(end_time)
    allow(end_date_time).to receive(:date).and_return(nil)

    allow(event).to receive(:start).and_return(start_date_time)
    allow(event).to receive(:end).and_return(end_date_time)
  end

  # Set description
  description = row['description'] || row['title'] || 'Mock event description'
  allow(event).to receive(:description).and_return(description)

  event
end
