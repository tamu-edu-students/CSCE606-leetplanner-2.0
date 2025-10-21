require 'rails_helper'

RSpec.describe Api::UsersController, type: :controller do
  let(:user) { create(:user, first_name: 'John', last_name: 'Doe', email: 'john.doe@tamu.edu') }

  describe 'GET #profile' do
    context 'when user is signed in' do
      before do
        # Simulate user session to bypass authenticate_user!
        allow(controller).to receive(:current_user).and_return(user)
      end

      it 'returns user profile data as JSON' do
        get :profile

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)
        expect(json_response).to include(
          'id' => user.id,
          'name' => user.full_name,
          'first_name' => user.first_name,
          'email' => user.email
        )
      end

      it 'includes all required fields in response' do
        get :profile

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('id')
        expect(json_response).to have_key('name')
        expect(json_response).to have_key('first_name')
        expect(json_response).to have_key('email')
      end

      it 'returns correct user data' do
        get :profile

        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(user.id)
        expect(json_response['name']).to eq('John Doe')
        expect(json_response['first_name']).to eq('John')
        expect(json_response['email']).to eq('john.doe@tamu.edu')
      end

      it 'returns success status when authenticated' do
        get :profile
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when user is not signed in' do
      before do
        # Simulate no user in session (which makes current_user return nil)
        allow(controller).to receive(:current_user).and_return(nil)
      end

      it 'returns unauthorized error as JSON (from authenticate_user!)' do
        get :profile, format: :json

        expect(response).to have_http_status(:unauthorized)
        expect(response.content_type).to include('application/json')
      end

      it 'returns authentication required error message (from authenticate_user!)' do
        get :profile, format: :json

        json_response = JSON.parse(response.body)
        expect(json_response).to include('error' => 'Authentication required')
      end

      it 'redirects to root for non-JSON requests' do
        get :profile

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(root_path)
      end
    end

    context 'testing controller logic directly (bypassing authenticate_user!)' do
      # This tests the actual controller logic by skipping authentication
      before do
        # Skip the authenticate_user! before_action for this test
        allow(controller).to receive(:authenticate_user!).and_return(true)
      end

      context 'when user_signed_in? returns true' do
        before do
          allow(controller).to receive(:user_signed_in?).and_return(true)
          allow(controller).to receive(:current_user).and_return(user)
        end

        it 'returns user profile data' do
          get :profile

          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response).to include(
            'id' => user.id,
            'name' => user.full_name,
            'first_name' => user.first_name,
            'email' => user.email
          )
        end
      end

      context 'when user_signed_in? returns false' do
        before do
          allow(controller).to receive(:user_signed_in?).and_return(false)
          allow(controller).to receive(:current_user).and_return(nil)
        end

        it 'returns not signed in error' do
          get :profile

          expect(response).to have_http_status(:unauthorized)
          json_response = JSON.parse(response.body)
          expect(json_response).to include('error' => 'Not signed in')
        end
      end
    end

    context 'when authentication state is inconsistent' do
      before do
        allow(controller).to receive(:authenticate_user!).and_return(true)
        allow(controller).to receive(:user_signed_in?).and_return(true)
        allow(controller).to receive(:current_user).and_return(nil)
      end

      it 'raises error when current_user is nil but user_signed_in? is true' do
        expect { get :profile }.to raise_error(NoMethodError)
      end
    end
  end
end
