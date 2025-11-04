require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  let(:user) { create(:user) }

  describe 'GET #debug' do
    it 'returns session data as plain text' do
      session[:test_key] = 'test_value'
      get :debug

      expect(response.content_type).to include('text/plain')
      expect(response.body).to include('test_key')
      expect(response.body).to include('test_value')
    end
  end

  describe 'POST #create' do
    let(:auth_hash) do
      {
        'info' => {
          'email' => 'user@tamu.edu',
          'first_name' => 'John',
          'last_name' => 'Doe'
        },
        'credentials' => {
          'token' => 'access_token_123',
          'refresh_token' => 'refresh_token_456',
          'expires_at' => 1.hour.from_now.to_i
        }
      }
    end

    before do
      ENV['ALLOWED_EMAIL_DOMAINS'] = 'tamu.edu'
      request.env['omniauth.auth'] = auth_hash
    end

    context 'with valid TAMU email' do
      it 'creates user session and redirects to dashboard' do
        expect {
          post :create
        }.to change(User, :count).by(1)

        user = User.last
        expect(user.email).to eq('user@tamu.edu')
        expect(user.netid).to eq('user')
        expect(user.google_access_token).to eq('access_token_123')
        expect(session[:user_id]).to eq(user.id)
        expect(response).to redirect_to(dashboard_path)
        expect(flash[:notice]).to eq('Signed in as user@tamu.edu')
      end

      it 'updates existing user without changing netid' do
        initial_count = User.count
        existing_user = create(:user, email: 'user@tamu.edu', netid: 'original_netid')

        post :create

        existing_user.reload
        expect(existing_user.netid).to eq('original_netid')
        expect(existing_user.first_name).to eq('John')
        expect(User.count).to eq(initial_count + 1)
      end

      it 'preserves refresh token when not provided in new auth' do
        existing_user = create(:user,
          email: 'user@tamu.edu',
          google_refresh_token: 'old_refresh_token'
        )
        auth_hash['credentials'].delete('refresh_token')
        request.env['omniauth.auth'] = auth_hash

        post :create

        existing_user.reload
        expect(existing_user.google_refresh_token).to eq('old_refresh_token')
      end
    end

    context 'with invalid email domain' do
      before do
        auth_hash['info']['email'] = 'user@gmail.com'
        request.env['omniauth.auth'] = auth_hash
      end

      it 'rejects non-TAMU emails' do
        expect {
          post :create
        }.not_to change(User, :count)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Login restricted to TAMU emails')
      end
    end

    context 'with missing auth data' do
      it 'handles missing auth gracefully' do
        request.env['omniauth.auth'] = nil

        post :create

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('No auth returned from Google')
      end
    end

    context 'when an error occurs' do
      before do
        allow(User).to receive(:find_or_initialize_by).and_raise(StandardError.new('Database error'))
      end

      it 'handles errors gracefully' do
        expect(Rails.logger).to receive(:error).with(/Google login error/)

        post :create

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Login failed.')
      end
    end
  end

  describe 'GET #failure' do
    it 'redirects to root with error message from params' do
      get :failure, params: { message: 'Access denied' }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('Access denied')
    end

    it 'uses default message when no message provided' do
      get :failure

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('Login failed')
    end
  end

  describe 'DELETE #destroy' do
    before do
      allow(controller).to receive(:current_user).and_return(user)
      session[:user_id] = user.id
    end

    it 'clears user tokens and session for HTML request' do
      user.update(
        google_access_token: 'token',
        google_refresh_token: 'refresh_token'
      )

      delete :destroy

      user.reload
      expect(user.google_access_token).to be_nil
      expect(user.google_refresh_token).to be_nil
      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq('You have been signed out successfully.')
    end

    it 'returns JSON response for API requests' do
      delete :destroy, format: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['message']).to eq('Signed out successfully.')
    end

    it 'handles logout when current_user is nil' do
      allow(controller).to receive(:current_user).and_return(nil)

      expect { delete :destroy }.not_to raise_error
      expect(response).to redirect_to(root_path)
    end
  end
end
