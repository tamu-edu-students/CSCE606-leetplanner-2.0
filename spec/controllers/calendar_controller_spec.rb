require 'rails_helper'

RSpec.describe CalendarController, type: :controller do
  let(:user) { create(:user) }
  let(:service_double) { instance_double(Google::Apis::CalendarV3::CalendarService) }
  let(:signet_client_double) { instance_double(Signet::OAuth2::Client) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:authenticate_user!).and_return(true)
    session[:user_id] = user.id

    allow(Signet::OAuth2::Client).to receive(:new).and_return(signet_client_double)
    allow(Google::Apis::CalendarV3::CalendarService).to receive(:new).and_return(service_double)
    allow(service_double).to receive(:authorization=)
  end

  describe 'authentication requirements' do
    before do
      allow(controller).to receive(:current_user).and_return(nil)
      session[:user_id] = nil
    end

    it 'redirects to login for unauthenticated users' do
      get :show
      expect(response).to redirect_to(login_google_path)
      expect(flash[:alert]).to eq('Please log in with Google to continue.')
    end
  end

  describe 'GET #show' do
    context 'when user is not authenticated with Google' do
      before { user.update(google_access_token: nil) }

      it 'redirects to Google login' do
        get :show
        expect(response).to redirect_to(login_google_path)
        expect(flash[:alert]).to eq('Please log in with Google to continue.')
      end
    end

    context 'when user has expired token' do
      before do
        user.update(
          google_access_token: 'expired_token',
          google_refresh_token: 'refresh_token',
          google_token_expires_at: Time.current - 1.hour
        )

        allow(signet_client_double).to receive(:refresh!)
        allow(signet_client_double).to receive(:access_token).and_return('new_token')
        allow(signet_client_double).to receive(:refresh_token).and_return('new_refresh_token')
        allow(signet_client_double).to receive(:expires_in).and_return(3600)

        allow(service_double).to receive(:list_events).and_return(
          double('response', items: [])
        )
      end

      it 'refreshes the token and continues' do
        get :show
        expect(user.reload.google_access_token).to eq('new_token')
        expect(response).to have_http_status(:success)
      end

      it 'handles token refresh failure' do
        allow(signet_client_double).to receive(:refresh!).and_raise(Signet::AuthorizationError.new('invalid_grant'))
              get :show
              expect(response).to redirect_to(login_google_path)
        expect(flash[:alert]).to eq('Authentication expired, please log in again.')
        expect(session[:user_id]).to be_nil
      end
    end

    context 'when user is authenticated with valid token' do
      before do
        user.update(
          google_access_token: 'valid_token',
          google_token_expires_at: Time.current + 1.hour
        )
      end

      it 'handles an invalid date parameter gracefully' do
        allow(service_double).to receive(:list_events).and_return(double('response', items: []))
        get :show, params: { date: 'invalid-date' }
        expect(assigns(:current_date)).to eq(Date.today)
        expect(response).to have_http_status(:success)
      end
          it 'correctly maps all-day events' do
        all_day_event = instance_double(Google::Apis::CalendarV3::Event,
          id: '456',
          summary: 'All Day Event',
          start: double('start', date_time: nil, date: '2025-10-28'),
          end: double('end', date_time: nil, date: '2025-10-29')
        )
        response_items = double('response_items', items: [ all_day_event ])
        allow(service_double).to receive(:list_events).and_return(response_items)
              get :show
              expect(assigns(:events).first[:summary]).to eq('All Day Event')
        expect(assigns(:events).first[:is_all_day]).to be true
        expect(assigns(:events).first[:start]).to eq(Date.parse('2025-10-28'))
      end

      it 'fetches and maps events successfully' do
        event_item = instance_double(Google::Apis::CalendarV3::Event,
          id: '123',
          summary: 'Test Event',
          start: double('start', date_time: Time.current, date: nil),
          end: double('end', date_time: Time.current + 1.hour, date: nil)
        )
        response_items = double('response_items', items: [ event_item ])
        allow(service_double).to receive(:list_events).and_return(response_items)

        get :show
        expect(assigns(:events).first[:summary]).to eq('Test Event')
        expect(assigns(:events).first[:is_all_day]).to be false
        expect(response).to render_template(:show)
      end

      it 'handles API errors gracefully' do
        allow(service_double).to receive(:list_events).and_raise(StandardError.new('API Error'))

        get :show
        expect(flash.now[:alert]).to eq('Failed to load calendar events.')
        expect(assigns(:events)).to eq([])
      end
    end
  end

  describe 'POST #sync' do
    let(:sync_result) { { success: true, synced: 5, updated: 2, deleted: 1 } }

    before do
      allow(GoogleCalendarSync).to receive(:sync_for_user).and_return(sync_result)
      request.env['HTTP_REFERER'] = calendar_path
    end

    it 'calls the sync service and displays success message' do
      post :sync
      expect(flash[:notice]).to include('Calendar synced successfully!')
      expect(response).to redirect_to(calendar_path)
    end

    it 'displays an error message if sync fails' do
      allow(GoogleCalendarSync).to receive(:sync_for_user).and_return(
        { success: false, error: 'API limit reached' }
      )

      post :sync
      expect(flash[:alert]).to eq('Sync failed: API limit reached')
      expect(response).to redirect_to(calendar_path)
    end
  end

  describe 'GET #new' do
    it 'creates a new event object and renders the new template' do
      get :new
      expect(assigns(:event)).to be_a(Google::Apis::CalendarV3::Event)
      expect(response).to render_template(:new)
    end
  end

  describe 'GET #edit' do
    let(:event_id) { 'event123' }

    before do
      user.update(
        google_access_token: 'valid_token',
        google_token_expires_at: Time.current + 1.hour
      )
    end

    it 'fetches and assigns an all-day event for editing' do
      google_event = instance_double(Google::Apis::CalendarV3::Event,
        id: event_id,
        summary: 'All Day Edit',
        description: nil,
        location: nil,
        start: double('start', date_time: nil, date: '2025-10-28'),
        end: double('end', date_time: nil, date: '2025-10-29')
      )
      allow(service_double).to receive(:get_event).with('primary', event_id).and_return(google_event)
          get :edit, params: { id: event_id }
          expect(assigns(:event)[:summary]).to eq('All Day Edit')
      expect(assigns(:event)[:is_all_day]).to be true
      expect(assigns(:event)[:start]).to eq(DateTime.parse('2025-10-28 00:00'))
    end

    it 'fetches and assigns the event for editing' do
      google_event = instance_double(Google::Apis::CalendarV3::Event,
        id: event_id,
        summary: 'Editable Event',
        description: 'Details',
        location: 'Office',
        start: double('start', date_time: Time.current, date: nil),
        end: double('end', date_time: Time.current + 1.hour, date: nil)
      )
      allow(service_double).to receive(:get_event).with('primary', event_id).and_return(google_event)

      get :edit, params: { id: event_id }
      expect(assigns(:event)[:summary]).to eq('Editable Event')
      expect(response).to render_template(:edit)
    end

    it 'redirects to calendar with an alert if event does not exist' do
      allow(service_double).to receive(:get_event).and_raise(
        Google::Apis::ClientError.new('Not found', status_code: 404)
      )

      get :edit, params: { id: 'nonexistent' }
      expect(response).to redirect_to(calendar_path)
      expect(flash[:alert]).to eq('Failed to load event.')
    end
  end

  describe 'private methods' do
    describe '#parse_date' do
      it 'returns the object if it is already a Date' do
        date_obj = Date.today
        expect(controller.send(:parse_date, date_obj)).to eq(date_obj)
      end
          it 'returns nil for an invalid date string' do
        expect(controller.send(:parse_date, "not-a-date")).to be_nil
      end
    end
  end
end
