require 'rails_helper'
require 'google/apis/calendar_v3'
require 'signet/oauth_2/client'

RSpec.describe GoogleCalendarSync do
  let(:user) { create(:user) }
  let(:session_hash) do
    {
      google_token: 'access_token',
      google_refresh_token: 'refresh_token',
      google_token_expires_at: 1.hour.from_now.to_i
    }
  end
  let(:sync_service) { described_class.new(user) }
  let(:mock_calendar_service) { instance_double('Google::Apis::CalendarV3::CalendarService') }
  let(:mock_client) { instance_double('Signet::OAuth2::Client') }

  before do
    allow(Signet::OAuth2::Client).to receive(:new).and_return(mock_client)
    allow(mock_client).to receive(:expired?).and_return(false)
    allow(Google::Apis::CalendarV3::CalendarService).to receive(:new).and_return(mock_calendar_service)
    allow(mock_calendar_service).to receive(:authorization=)
  end

  describe '#initialize' do
    it 'initializes with a user' do
      expect(sync_service.instance_variable_get(:@user)).to eq(user)
    end

    it 'initializes with empty session hash' do
      expect(sync_service.instance_variable_get(:@session)).to eq({})
    end
  end

  describe '.sync_for_user' do
    let(:google_event_1) do
      double('Event',
        id: 'google_event_1',
        summary: 'Team Meeting',
        description: 'Weekly team sync',
        start: double(date_time: 1.day.from_now, date: nil),
        end: double(date_time: (1.day.from_now + 1.hour), date: nil),
        status: 'confirmed'
      )
    end

    let(:events_response) do
      double('Events', items: [ google_event_1 ])
    end

    before do
      allow(mock_calendar_service).to receive(:list_events).and_return(events_response)
    end

    it 'creates a new instance and calls sync' do
      result = described_class.sync_for_user(user, session_hash)
      expect(result[:success]).to be true
    end
  end

  describe '#sync' do
    let(:google_event_1) do
      double('Event',
        id: 'google_event_1',
        summary: 'Team Meeting',
        description: 'Weekly team sync',
        start: double(date_time: 1.day.from_now, date: nil),
        end: double(date_time: (1.day.from_now + 1.hour), date: nil),
        status: 'confirmed'
      )
    end

    let(:google_event_2) do
      double('Event',
        id: 'google_event_2',
        summary: 'Lunch Break',
        description: 'Lunch',
        start: double(date_time: 2.days.from_now, date: nil),
        end: double(date_time: (2.days.from_now + 30.minutes), date: nil),
        status: 'confirmed'
      )
    end

    let(:cancelled_event) do
      double('Event',
        id: 'cancelled_event',
        summary: 'Cancelled Meeting',
        start: double(date_time: 3.days.from_now, date: nil),
        end: double(date_time: (3.days.from_now + 1.hour), date: nil),
        status: 'cancelled'
      )
    end

    let(:all_day_event) do
      double('Event',
        id: 'all_day_event',
        summary: 'Holiday',
        description: 'All day holiday',
        start: double(date_time: nil, date: 4.days.from_now.to_date.iso8601),
        end: double(date_time: nil, date: 5.days.from_now.to_date.iso8601),
        status: 'confirmed'
      )
    end

    let(:events_response) do
      double('Events', items: [ google_event_1, google_event_2, cancelled_event, all_day_event ])
    end

    before do
      allow(mock_calendar_service).to receive(:list_events).and_return(events_response)
    end

    context 'when sync is successful' do
      it 'creates new LeetCode sessions from Google events' do
        expect {
          sync_service.sync(session_hash)
        }.to change(LeetCodeSession, :count).by(2) # 2 regular events (skips cancelled and all-day)
      end

      it 'saves session details correctly' do
        sync_service.sync(session_hash)

        session = LeetCodeSession.find_by(google_event_id: 'google_event_1')
        expect(session.title).to eq('Team Meeting')
        expect(session.description).to eq('Weekly team sync')
        expect(session.user).to eq(user)
        expect(session.duration_minutes).to eq(60)
      end

      it 'skips cancelled events' do
        sync_service.sync(session_hash)

        expect(LeetCodeSession.find_by(google_event_id: 'cancelled_event')).to be_nil
      end

      it 'skips all-day events' do
        sync_service.sync(session_hash)

        expect(LeetCodeSession.find_by(google_event_id: 'all_day_event')).to be_nil
      end

      it 'calls Google Calendar API with correct parameters' do
        expect(mock_calendar_service).to receive(:list_events).with(
          'primary',
          hash_including(
            single_events: true,
            order_by: 'startTime',
            time_min: anything,
            time_max: anything
          )
        )
        sync_service.sync(session_hash)
      end

      it 'returns success status with statistics' do
        result = sync_service.sync(session_hash)
        expect(result[:success]).to be true
        expect(result[:synced]).to eq(2)
        expect(result[:updated]).to eq(0)
        expect(result[:skipped]).to eq(0)
        expect(result[:deleted]).to eq(0)
      end

      it 'determines status based on event time' do
        past_event = double('Event',
          id: 'past_event',
          summary: 'Past Meeting',
          description: 'Past',
          start: double(date_time: 2.days.ago, date: nil),
          end: double(date_time: (2.days.ago + 1.hour), date: nil),
          status: 'confirmed'
        )

        allow(events_response).to receive(:items).and_return([ past_event ])
        sync_service.sync(session_hash)

        session = LeetCodeSession.find_by(google_event_id: 'past_event')
        expect(session.status).to eq('completed')
      end
    end

    context 'when updating existing sessions' do
      let!(:existing_session) do
        create(:leet_code_session,
          user: user,
          google_event_id: 'google_event_1',
          title: 'Old Title',
          description: 'Old Description',
          duration_minutes: 30
        )
      end

      it 'updates existing sessions instead of creating duplicates' do
        expect {
          sync_service.sync(session_hash)
        }.to change(LeetCodeSession, :count).by(1) # Only 1 new session
      end

      it 'updates session details' do
        sync_service.sync(session_hash)

        existing_session.reload
        expect(existing_session.title).to eq('Team Meeting')
        expect(existing_session.description).to eq('Weekly team sync')
        expect(existing_session.duration_minutes).to eq(60)
      end

      it 'returns correct update statistics' do
        result = sync_service.sync(session_hash)
        expect(result[:updated]).to eq(1)
        expect(result[:synced]).to eq(1) # The other event
      end
    end

    context 'when session attributes have not changed' do
      let(:start_time) { 1.day.from_now }

      let!(:existing_session) do
        create(:leet_code_session,
          user: user,
          google_event_id: 'google_event_1',
          title: 'Team Meeting',
          description: 'Weekly team sync',
          scheduled_time: start_time,
          duration_minutes: 60,
          status: 'scheduled'
        )
      end

      before do
        # Mock the event to have exact same times
        allow(google_event_1).to receive(:start).and_return(double(date_time: start_time, date: nil))
        allow(google_event_1).to receive(:end).and_return(double(date_time: start_time + 1.hour, date: nil))
      end

      it 'skips unchanged sessions' do
        result = sync_service.sync(session_hash)
        expect(result[:skipped]).to eq(1)
        expect(result[:synced]).to eq(1) # google_event_2
      end
    end

    context 'when cleaning up deleted events' do
      let!(:deleted_session) do
        create(:leet_code_session,
          user: user,
          google_event_id: 'deleted_event_id',
          title: 'Deleted Event'
        )
      end

      it 'deletes local sessions that no longer exist in Google' do
        expect {
          sync_service.sync(session_hash)
        }.to change(LeetCodeSession, :count).by(1) # +2 new -1 deleted
      end

      it 'returns correct deletion statistics' do
        result = sync_service.sync(session_hash)
        expect(result[:deleted]).to eq(1)
      end

      it 'does not delete sessions without google_event_id' do
        local_only_session = create(:leet_code_session,
          user: user,
          google_event_id: nil,
          title: 'Local Only'
        )

        sync_service.sync(session_hash)
        expect(LeetCodeSession.exists?(local_only_session.id)).to be true
      end
    end

    context 'when not authenticated' do
      let(:session_without_token) { {} }

      it 'returns failure status' do
        result = sync_service.sync(session_without_token)
        expect(result[:success]).to be false
        expect(result[:error]).to eq('Not authenticated')
      end

      it 'does not create any sessions' do
        expect {
          sync_service.sync(session_without_token)
        }.not_to change(LeetCodeSession, :count)
      end
    end

    context 'when token is expired' do
      before do
        allow(mock_client).to receive(:expired?).and_return(true)
        allow(mock_client).to receive(:refresh!).and_raise(Signet::AuthorizationError.new('Token expired'))
      end

      it 'returns failure status' do
        result = sync_service.sync(session_hash)
        expect(result[:success]).to be false
        expect(result[:error]).to eq('Authentication expired')
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/Token refresh failed/)
        sync_service.sync(session_hash)
      end
    end

    context 'when token needs refresh but succeeds' do
      before do
        allow(mock_client).to receive(:expired?).and_return(true)
        allow(mock_client).to receive(:refresh!)
        allow(mock_client).to receive(:access_token).and_return('new_access_token')
        allow(mock_client).to receive(:refresh_token).and_return('new_refresh_token')
        allow(mock_client).to receive(:expires_at).and_return(2.hours.from_now.to_i)
      end

      it 'refreshes the token' do
        expect(mock_client).to receive(:refresh!)
        sync_service.sync(session_hash)
      end

      it 'updates session with new token' do
        sync_service.sync(session_hash)
        expect(session_hash[:google_token]).to eq('new_access_token')
        expect(session_hash[:google_token_expires_at]).to be_a(Integer)
      end

      it 'continues with sync after refresh' do
        result = sync_service.sync(session_hash)
        expect(result[:success]).to be true
      end
    end

    context 'when Google Calendar API fails' do
      before do
        allow(mock_calendar_service).to receive(:list_events)
          .and_raise(Google::Apis::Error.new('API Error'))
      end

      it 'returns failure status' do
        result = sync_service.sync(session_hash)
        expect(result[:success]).to be false
        expect(result[:error]).to eq('Failed to fetch calendar events')
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/Google Calendar API error/)
        sync_service.sync(session_hash)
      end

      it 'does not create any sessions' do
        expect {
          sync_service.sync(session_hash)
        }.not_to change(LeetCodeSession, :count)
      end
    end

    context 'when processing an individual event fails' do
      let(:failed_session) { instance_double(LeetCodeSession) }

      before do
        # Allow normal processing for google_event_2
        allow(LeetCodeSession).to receive(:find_or_initialize_by).and_call_original

        # Make google_event_1 raise an error during processing
        allow(LeetCodeSession).to receive(:find_or_initialize_by)
          .with(user_id: user.id, google_event_id: 'google_event_1')
          .and_raise(StandardError.new('Processing error'))
      end

      it 'logs the error and continues' do
        expect(Rails.logger).to receive(:error).with(/Failed to sync event google_event_1: Processing error/)
        sync_service.sync(session_hash)
      end

      it 'creates other events successfully' do
        expect {
          sync_service.sync(session_hash)
        }.to change(LeetCodeSession, :count).by(1) # Only google_event_2
      end

      it 'returns success with partial results' do
        result = sync_service.sync(session_hash)
        expect(result[:success]).to be true
        expect(result[:synced]).to eq(1) # Only google_event_2
        expect(result[:skipped]).to eq(1) # google_event_1 failed
      end
    end

    context 'when a generic StandardError occurs during sync' do
      before do
        allow(mock_client).to receive(:expired?).and_return(false)

        # Mock Google Calendar service to raise a plain StandardError
        allow(mock_calendar_service).to receive(:list_events)
                                          .and_raise(StandardError.new('Unexpected runtime failure'))
      end

      it 'logs the error and returns failure result with the message' do
        expect(Rails.logger).to receive(:error).with(/Calendar sync error: Unexpected runtime failure/)

        result = sync_service.sync(session_hash)

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Unexpected runtime failure')
      end
    end
  end

  describe 'private methods' do
    describe '#calculate_duration' do
      it 'calculates duration correctly in minutes' do
        start_time = Time.current
        end_time = start_time + 90.minutes

        duration = sync_service.send(:calculate_duration, start_time, end_time)
        expect(duration).to eq(90)
      end

      it 'handles DateTime objects' do
        start_time = 1.day.from_now
        end_time = start_time + 45.minutes

        duration = sync_service.send(:calculate_duration, start_time, end_time)
        expect(duration).to eq(45)
      end

      it 'returns minimum 1 minute for very short durations' do
        start_time = Time.current
        end_time = start_time + 30.seconds

        duration = sync_service.send(:calculate_duration, start_time, end_time)
        expect(duration).to eq(1)
      end
    end

    describe '#determine_status' do
      it 'returns completed for past events' do
        start_time = 2.days.ago
        end_time = 2.days.ago + 1.hour

        status = sync_service.send(:determine_status, start_time, end_time)
        expect(status).to eq('completed')
      end

      it 'returns scheduled for future events' do
        start_time = 2.days.from_now
        end_time = 2.days.from_now + 1.hour

        status = sync_service.send(:determine_status, start_time, end_time)
        expect(status).to eq('scheduled')
      end

      it 'returns scheduled for ongoing events' do
        start_time = 10.minutes.ago
        end_time = 50.minutes.from_now

        status = sync_service.send(:determine_status, start_time, end_time)
        expect(status).to eq('scheduled')
      end
    end

    describe '#build_oauth_client' do
      it 'returns nil when no token in session' do
        sync_service.instance_variable_set(:@session, {})
        client = sync_service.send(:build_oauth_client)
        expect(client).to be_nil
      end

      it 'builds client with correct parameters' do
        sync_service.instance_variable_set(:@session, session_hash)

        expect(Signet::OAuth2::Client).to receive(:new).with(
          hash_including(
            access_token: 'access_token',
            refresh_token: 'refresh_token',
            client_id: ENV['GOOGLE_CLIENT_ID'],
            client_secret: ENV['GOOGLE_CLIENT_SECRET']
          )
        )

        sync_service.send(:build_oauth_client)
      end
    end
  end
end
