require 'rails_helper'

RSpec.describe Api::CalendarController, type: :controller do
  let(:user) { create(:user) }
  let(:google_service) { instance_double(Google::Apis::CalendarV3::CalendarService) }
  let(:signet_client) { instance_double(Signet::OAuth2::Client) }
  let(:mock_event) do
    instance_double(Google::Apis::CalendarV3::Event,
      id: '123',
      summary: 'Test Event',
      start: double(date_time: Time.current.iso8601, date: nil),
      end: double(date_time: (Time.current + 1.hour).iso8601, date: nil),
      location: 'Test Location',
      description: 'Test Description'
    )
  end

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(Signet::OAuth2::Client).to receive(:new).and_return(signet_client)
    allow(signet_client).to receive(:refresh!)
    allow(signet_client).to receive(:access_token).and_return('refreshed-access-token')
    allow(signet_client).to receive(:refresh_token).and_return('refreshed-refresh-token')
    allow(signet_client).to receive(:expires_at).and_return(Time.current.to_i + 3600)
    allow(Google::Apis::CalendarV3::CalendarService).to receive(:new).and_return(google_service)
    allow(google_service).to receive(:authorization=)

    session[:user_id] = user.id
  end

  describe 'authentication and authorization' do
    context 'when user has no google token in session' do
      it 'redirects to google login for all actions' do
        get :events
        expect(response).to redirect_to(login_google_path)
        expect(flash[:alert]).to eq('Not authenticated with Google.')

        post :create, params: { event: { summary: 'Test' } }
        expect(response).to redirect_to(login_google_path)
        expect(flash[:alert]).to eq('Please log in with Google to continue.')
      end
    end

    context 'when token refresh fails' do
      before do
        session[:google_token] = 'stale-token'
        session[:google_token_expires_at] = Time.current.to_i - 3600
        allow(signet_client).to receive(:refresh!).and_raise(Signet::AuthorizationError.new('Refresh failed'))
      end

      it 'resets session and redirects to login' do
        post :create, params: { event: { summary: 'Test' } }
        expect(session[:google_token]).to be_nil
        expect(response).to redirect_to(login_google_path)
        expect(flash[:alert]).to match(/Your session expired/)
      end
    end
  end

  context 'with valid google session' do
    before do
      session[:google_token] = 'valid-token'
      session[:google_token_expires_at] = Time.current.to_i + 3600
    end

    describe 'GET #events' do
      let(:events_response) { double(items: [ mock_event ]) }

      before do
        allow(google_service).to receive(:list_events).and_return(events_response)
      end

      it 'fetches events and redirects with success message' do
        get :events
        expect(google_service).to have_received(:list_events).with(
          'primary',
          hash_including(
            single_events: true,
            order_by: 'startTime',
            max_results: 50
          )
        )
        expect(response).to redirect_to(calendar_path(anchor: 'calendar'))
        expect(flash[:notice]).to eq('Events loaded.')
      end

      it 'uses custom date range when provided' do
        get :events, params: { start_date: '2025-01-01T00:00:00Z', end_date: '2025-01-31T23:59:59Z' }
        expect(google_service).to have_received(:list_events).with(
          'primary',
          hash_including(
            time_min: '2025-01-01T00:00:00Z',
            time_max: '2025-01-31T23:59:59Z'
          )
        )
      end

      it 'handles authorization errors' do
        allow(google_service).to receive(:list_events).and_raise(Google::Apis::AuthorizationError.new('Unauthorized'))
        get :events
        expect(response).to redirect_to(dashboard_path(anchor: 'calendar'))
        expect(flash[:alert]).to eq('Failed to load events due to authorization.')
      end

      it 'handles general API errors' do
        allow(google_service).to receive(:list_events).and_raise(StandardError.new('API Error'))
        get :events
        expect(response).to redirect_to(calendar_path(anchor: 'calendar'))
        expect(flash[:alert]).to eq('Failed to load events.')
      end
    end

    describe 'POST #create' do
      let(:valid_params) { { summary: 'New Event', start_date: '2025-10-26', start_time: '14:00' } }
      let(:created_event) { mock_event }

      before do
        allow(google_service).to receive(:insert_event).and_return(created_event)
        allow(LeetCodeSession).to receive(:create!)
      end

      context 'with valid parameters' do
        it 'creates timed event and LeetCode session' do
          post :create, params: { event: valid_params }

          expect(google_service).to have_received(:insert_event)
          expect(LeetCodeSession).to have_received(:create!).with(
            hash_including(
              user_id: user.id,
              google_event_id: '123',
              title: 'New Event'
            )
          )
          expect(response).to redirect_to(calendar_path)
          expect(flash[:notice]).to eq('Event successfully created.')
        end

        it 'creates all-day event when all_day is true' do
          post :create, params: { event: valid_params.merge(all_day: true) }
          expect(google_service).to have_received(:insert_event) do |calendar_id, event|
            expect(event.start.date).to be_present
            expect(event.start.date_time).to be_nil
          end
        end

        it 'returns JSON for API requests' do
          post :create, params: { event: valid_params }, format: :json
          expect(response).to have_http_status(:created)
          expect(JSON.parse(response.body)).to include('summary' => 'Test Event')
        end

        it 'uses default end time when not provided' do
          post :create, params: { event: valid_params }
          expect(google_service).to have_received(:insert_event) do |calendar_id, event|
            start_time = Time.zone.parse(event.start.date_time)
            end_time = Time.zone.parse(event.end.date_time)
            expect(end_time - start_time).to eq(30.minutes)
          end
        end

        it 'sets status to "completed" for events created in the past' do
          travel_to(1.day.from_now) do # Simulate current time being in the future
            # This event is now in the past relative to the traveled time
            post :create, params: { event: { summary: 'Past Event', start_date: Date.current.yesterday.to_s, start_time: '10:00' } }
            
            expect(LeetCodeSession).to have_received(:create!).with(hash_including(status: 'completed'))
          end
        end
      end

      context 'without event name' do
        it 'returns error for missing summary' do
          request.env["HTTP_REFERER"] = calendar_path
          post :create, params: { event: { summary: '' } }
          expect(response).to redirect_to(calendar_path)
          expect(flash[:alert]).to eq('Event name is required.')
        end

        it 'returns JSON error for API requests' do
          post :create, params: { event: { summary: '' } }, format: :json
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['error']).to eq('Event name is required.')
        end
      end

      context 'when Google API fails' do
        before do
          allow(google_service).to receive(:insert_event).and_raise(Google::Apis::ClientError.new('API Error'))
        end

        it 'handles creation errors gracefully' do
          post :create, params: { event: valid_params }
          expect(response).to redirect_to(calendar_path)
          expect(flash[:alert]).to eq('API Error')
        end

        it 'returns JSON error for API requests' do
          post :create, params: { event: valid_params }, format: :json
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['error']).to eq('API Error')
        end
      end
    end

    describe 'PATCH #update' do
      let(:event_id) { 'event123' }
      let(:update_params) { { summary: 'Updated Event', start_date: '2025-10-27', start_time: '15:00' } }

      before do
        allow(google_service).to receive(:get_event).and_return(mock_event)
        allow(google_service).to receive(:update_event).and_return(mock_event)
      end

      context 'with valid parameters' do
        it 'updates the event successfully' do
          patch :update, params: { id: event_id, event: update_params }

          expect(google_service).to have_received(:get_event).with('primary', event_id)
          expect(google_service).to have_received(:update_event).with('primary', event_id, anything)
          expect(response).to redirect_to(calendar_path)
          expect(flash[:notice]).to eq('Event successfully updated.')
        end

        it 'handles all-day events' do
          patch :update, params: { id: event_id, event: update_params.merge(all_day: true) }
          expect(google_service).to have_received(:update_event) do |calendar_id, id, patch|
            expect(patch.start.date).to be_present
            expect(patch.start.date_time).to be_nil
          end
        end

        it 'returns JSON for API requests' do
          patch :update, params: { id: event_id, event: update_params }, format: :json
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)).to include('summary' => 'Test Event')
        end

        it 'updates with a default end time if only start time is provided' do
          # Add a summary to the params to pass the before_action
          patch :update, params: { id: event_id, event: { summary: 'Event with no end time', start_time: '16:00' } }
          
          expect(google_service).to have_received(:update_event) do |_, _, patch|
            start_time = Time.zone.parse(patch.start.date_time)
            end_time = Time.zone.parse(patch.end.date_time)
            expect(end_time - start_time).to eq(30.minutes)
          end
        end
      end

      context 'without event name' do
        it 'returns error for missing summary' do
          request.env["HTTP_REFERER"] = calendar_path
          patch :update, params: { id: event_id, event: { summary: '' } }
          expect(response).to redirect_to(calendar_path)
          expect(flash[:alert]).to eq('Event name is required.')
        end
      end

      context 'when Google API fails' do
        before do
          allow(google_service).to receive(:update_event).and_raise(Google::Apis::ClientError.new('Update failed'))
        end

        it 'handles update errors gracefully' do
          patch :update, params: { id: event_id, event: update_params }
          expect(response).to redirect_to(calendar_path)
          expect(flash[:alert]).to eq('Failed to update event.')
        end
      end
    end

    describe 'DELETE #destroy' do
      let(:event_id) { 'event_to_delete' }

      it 'deletes event successfully' do
        expect(google_service).to receive(:delete_event).with('primary', event_id)
        delete :destroy, params: { id: event_id }
        expect(response).to redirect_to(calendar_path(anchor: 'calendar'))
        expect(flash[:notice]).to eq('Event deleted.')
      end

      it 'handles deletion errors gracefully' do
        allow(google_service).to receive(:delete_event).and_raise(Google::Apis::ClientError.new('Not found'))
        delete :destroy, params: { id: event_id }
        expect(response).to redirect_to(calendar_path(anchor: 'calendar'))
        expect(flash[:alert]).to eq('Failed to delete event.')
      end
    end

    describe 'private methods' do
      describe '#event_time' do
        it 'returns nil for blank input' do
          expect(controller.send(:event_time, nil, false)).to be_nil
          expect(controller.send(:event_time, '', false)).to be_nil
        end

        it 'handles all-day flag' do
          result = controller.send(:event_time, '2025-10-28', true)
          expect(result.date).to eq('2025-10-28')
          expect(result.date_time).to be_nil
        end

        it 'handles date-only string' do
          result = controller.send(:event_time, '2025-10-28', false)
          expect(result.date).to eq('2025-10-28')
          expect(result.date_time).to be_nil
        end

        it 'handles datetime string' do
          result = controller.send(:event_time, '2025-10-28T10:00:00', false)
          expect(result.date_time).to include('2025-10-28T10:00:00')
          expect(result.date).to be_nil
        end

        it 'returns a valid object with nil date/datetime for invalid input' do
          result = controller.send(:event_time, 'invalid date', false)
          expect(result.date).to be_nil
          expect(result.date_time).to be_nil
        end
      end

      describe '#calendar_service_or_unauthorized' do
        it 'refreshes token when near expiry' do
          session[:google_token_expires_at] = (Time.current + 2.minutes).to_i
          allow(controller).to receive(:redirect_to)

          controller.send(:calendar_service_or_unauthorized)
          expect(signet_client).to have_received(:refresh!)
        end

        it 'refreshes token when no expiry time stored' do
          session.delete(:google_token_expires_at)
          allow(controller).to receive(:redirect_to)

          controller.send(:calendar_service_or_unauthorized)
          expect(signet_client).to have_received(:refresh!)
        end
      end

      describe '#serialize_event' do
        it 'handles all-day events correctly' do
          all_day_event = instance_double(Google::Apis::CalendarV3::Event,
            id: '456',
            summary: 'All Day',
            start: double(date: '2025-10-28', date_time: nil),
            end: double(date: '2025-10-29', date_time: nil),
            location: nil,
            description: nil
          )
          result = controller.send(:serialize_event, all_day_event)
          expect(result).to include(
            start: '2025-10-28',
            end: '2025-10-29'
          )
        end
        
        it 'converts Google event to hash format' do
          result = controller.send(:serialize_event, mock_event)
          expect(result).to include(
            id: '123',
            summary: 'Test Event',
            location: 'Test Location',
            description: 'Test Description'
          )
        end
      end
    end
  end
end
