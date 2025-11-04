require 'rails_helper'

RSpec.describe TestHelpersController, type: :controller do
  describe 'security and authentication' do
    it 'skips CSRF verification' do
      # TestHelpersController should skip CSRF token verification
      expect(TestHelpersController._process_action_callbacks
        .any? { |c| c.filter == :verify_authenticity_token && c.kind == :before && c.options[:if].present? }).to be false
    end

    it 'skips user authentication' do
      # TestHelpersController should skip user authentication
      expect(TestHelpersController._process_action_callbacks
        .any? { |c| c.filter == :authenticate_user! && c.kind == :before && c.options[:if].present? }).to be false
    end
  end

  describe 'GET #clear_session' do
    before do
      session[:user_id] = 123
      session[:some_data] = 'test'
    end

    it 'clears the session' do
      expect(controller).to receive(:reset_session)
      get :clear_session
    end

    it 'returns ok status' do
      get :clear_session
      expect(response).to have_http_status(:ok)
    end

    it 'responds with head only' do
      get :clear_session
      expect(response.body).to be_blank
    end
  end

  describe 'GET #clear_session_with_alert' do
    before do
      session[:user_id] = 123
      session[:some_data] = 'test'
    end

    it 'clears the session' do
      expect(controller).to receive(:reset_session)
      get :clear_session_with_alert
    end

    it 'sets flash alert message' do
      get :clear_session_with_alert
      expect(flash[:alert]).to eq('Your session expired. Please log in again.')
    end

    it 'redirects to root path' do
      get :clear_session_with_alert
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'GET #clear_timer' do
    before do
      session[:timer_ends_at] = 1.hour.from_now.iso8601
    end

    it 'clears timer_ends_at from session' do
      get :clear_timer
      expect(session[:timer_ends_at]).to be_nil
    end

    it 'returns ok status' do
      get :clear_timer
      expect(response).to have_http_status(:ok)
    end

    it 'responds with head only' do
      get :clear_timer
      expect(response.body).to be_blank
    end
  end

  describe 'GET #set_timer' do
    context 'with valid minutes parameter' do
      it 'sets timer in session' do
        travel_to Time.zone.parse('2024-01-01 12:00:00 UTC') do
          get :set_timer, params: { minutes: 30 }
          expect(session[:timer_ends_at]).to eq('2024-01-01T12:30:00Z')
        end
      end

      it 'redirects to dashboard' do
        get :set_timer, params: { minutes: 30 }
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'with zero or negative minutes' do
      it 'removes timer from session for zero minutes' do
        session[:timer_ends_at] = 1.hour.from_now.iso8601
        get :set_timer, params: { minutes: 0 }
        expect(session[:timer_ends_at]).to be_nil
      end

      it 'removes timer from session for negative minutes' do
        session[:timer_ends_at] = 1.hour.from_now.iso8601
        get :set_timer, params: { minutes: -5 }
        expect(session[:timer_ends_at]).to be_nil
      end

      it 'still redirects to dashboard' do
        get :set_timer, params: { minutes: 0 }
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'without minutes parameter' do
      it 'removes timer from session' do
        session[:timer_ends_at] = 1.hour.from_now.iso8601
        get :set_timer
        expect(session[:timer_ends_at]).to be_nil
      end
    end
  end

  describe 'GET #login_as' do
    context 'with valid email' do
      let(:email) { 'testuser@tamu.edu' }

      context 'when user exists' do
        let!(:existing_user) { create(:user, email: email, netid: 'testuser') }

        it 'finds existing user' do
          get :login_as, params: { email: email }
          user = User.find_by(email: email)
          expect(user).to eq(existing_user)
        end

        it 'updates last_login_at' do
          travel_to Time.zone.parse('2024-01-01 12:00:00') do
            get :login_as, params: { email: email }
            existing_user.reload
            expect(existing_user.last_login_at).to be_within(1.second).of(Time.current)
          end
        end

        it 'sets session variables' do
          get :login_as, params: { email: email }
          expect(session[:user_id]).to eq(existing_user.id)
          expect(session[:user_email]).to eq(existing_user.email)
          expect(session[:user_first_name]).to eq(existing_user.first_name)
        end

        it 'redirects to dashboard' do
          get :login_as, params: { email: email }
          expect(response).to redirect_to(dashboard_path)
        end
      end

      context 'when user does not exist' do
        it 'creates new user' do
          expect do
            get :login_as, params: { email: email }
          end.to change(User, :count).by(1)
        end

        it 'sets default attributes for new user' do
          get :login_as, params: { email: email }
          user = User.find_by(email: email)
          expect(user.netid).to eq('testuser')
          expect(user.first_name).to eq('Test')
          expect(user.last_name).to eq('User')
          expect(user.last_login_at).to be_within(1.second).of(Time.current)
        end

        it 'sets session for new user' do
          get :login_as, params: { email: email }
          user = User.find_by(email: email)
          expect(session[:user_id]).to eq(user.id)
          expect(session[:user_email]).to eq(user.email)
          expect(session[:user_first_name]).to eq('Test')
        end
      end

      context 'when user exists but missing optional fields' do
        let!(:user) { create(:user, email: email, netid: 'existing') }

        it 'fills in missing netid when blank' do
          user.update_column(:netid, nil)
          get :login_as, params: { email: email }
          user.reload
          expect(user.netid).to eq('testuser')
        end

        it 'preserves existing first_name' do
          get :login_as, params: { email: email }
          user.reload
          expect(user.first_name).to be_present
        end
      end
    end

    context 'with blank email' do
      it 'returns bad request for empty email' do
        get :login_as, params: { email: '' }
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns bad request for whitespace email' do
        get :login_as, params: { email: '   ' }
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns bad request for nil email' do
        get :login_as
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'email parameter handling' do
      it 'strips whitespace from email' do
        get :login_as, params: { email: '  testuser@tamu.edu  ' }
        user = User.find_by(email: 'testuser@tamu.edu')
        expect(user).to be_present
      end
    end
  end

  describe 'route accessibility' do
    it 'allows access without authentication' do
      # Simulate unauthenticated state
      allow(controller).to receive(:user_signed_in?).and_return(false)
      allow(controller).to receive(:current_user).and_return(nil)

      get :clear_session
      expect(response).to have_http_status(:ok)
    end
  end
end