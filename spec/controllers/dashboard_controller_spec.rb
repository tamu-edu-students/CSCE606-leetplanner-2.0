require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  let(:user) { create(:user) }
  before do
    session[:user_id] = user.id
  end

  describe 'GET #show' do
    context 'without a google token in session' do
      it 'renders successfully without an event' do
        get :show
        expect(response).to have_http_status(:success)
        expect(assigns(:current_event)).to be_nil
      end
    end

    context 'with a google token in session' do
      let(:google_service) { instance_double(Google::Apis::CalendarV3::CalendarService) }

      before do
        session[:user_id] = user.id
        session[:google_token] = 'fake-token'
        allow(Google::Apis::CalendarV3::CalendarService).to receive(:new).and_return(google_service)
        allow(google_service).to receive(:authorization=)
      end

      context 'when a timed event is currently active' do
        it 'assigns the current event and remaining time' do
          travel_to Time.current do # Freezes time for this block
            now = Time.current.utc
            active_event = instance_double(Google::Apis::CalendarV3::Event,
              start: double('start', date_time: now - 30.minutes, date: nil),
              end: double('end', date_time: now + 30.minutes, date: nil),
              description: "A test event" # Add any other attributes your view might need
            )
            response_items = double('response_items', items: [ active_event ])
            allow(google_service).to receive(:list_events).and_return(response_items)

            get :show

            expect(assigns(:current_event)).to eq(active_event)
            expect(assigns(:time_remaining_hms)).to eq("00:30:00")
          end
        end
      end
          context 'when an all-day event is active' do
        it 'assigns the event and calculates time remaining until end of day' do
          travel_to Time.current.middle_of_day do # Set time to noon for clarity
            now = Time.current.utc
            all_day_event = instance_double(Google::Apis::CalendarV3::Event,
              start: double('start', date: now.to_date.to_s, date_time: nil),
              end: double('end', date: (now.to_date + 1.day).to_s, date_time: nil),
              description: "An all-day event"
            )
            response_items = double('response_items', items: [ all_day_event ])
            allow(google_service).to receive(:list_events).and_return(response_items)

            get :show

            expect(assigns(:current_event)).to eq(all_day_event)
            # Time should be remaining until midnight
            expect(assigns(:time_remaining_hms)).to match(/11:59:\d{2}/)
          end
        end
      end

      context 'when no event is active but a custom timer is running' do
        let(:response_items) { double('response_items', items: []) }
        before do
          allow(google_service).to receive(:list_events).and_return(response_items)
          session[:timer_ends_at] = (Time.current + 15.minutes).iso8601
        end
        it 'calculates the remaining time for the custom timer' do
          get :show
          expect(assigns(:current_event)).to be_nil
          expect(assigns(:time_remaining_hms)).to match(/00:14:\d{2}|00:15:00/)
        end
      end

      context 'when an expired custom timer is in the session' do
        let(:response_items) { double('response_items', items: []) }
        before do
          allow(google_service).to receive(:list_events).and_return(response_items)
          session[:timer_ends_at] = (Time.current - 5.minutes).iso8601
        end
        it 'clears the timer from the session' do
          get :show
          expect(session[:timer_ends_at]).to be_nil
          expect(assigns(:time_remaining_hms)).to be_nil
        end
      end
          context 'when Google Calendar API fails' do
        before do
          allow(google_service).to receive(:list_events).and_raise(Google::Apis::ServerError.new('Service unavailable'))
          allow(Rails.logger).to receive(:error) # Stub logger to check if it's called
        end

        it 'sets a flash error and logs the error' do
          get :show
          expect(flash.now[:error]).to eq('Unable to sync with Google Calendar')
          expect(Rails.logger).to have_received(:error).with(/Google Calendar sync failed: Google::Apis::ServerError Service unavailable/)
        end
      end

      context 'when a standard error occurs' do
        before do
          allow(google_service).to receive(:list_events).and_raise(StandardError.new('Something went wrong'))
          allow(Rails.logger).to receive(:error)
        end
              it 'logs the error but does not crash' do
          get :show
          expect(response).to have_http_status(:success)
          expect(Rails.logger).to have_received(:error).with(/Dashboard#show error: StandardError Something went wrong/)
        end
      end
    end
  end

  describe 'POST #create_timer' do
    it 'sets the timer in the session for valid minutes' do
      post :create_timer, params: { minutes: '25' }
      expect(session[:timer_ends_at]).to be_present
    end

    it 'does not set the timer for invalid minutes' do
      post :create_timer, params: { minutes: '0' }
      expect(session[:timer_ends_at]).to be_nil
    end

    it 'redirects to the dashboard' do
      post :create_timer, params: { minutes: '10' }
      expect(response).to redirect_to(dashboard_path)
    end
  end
end
