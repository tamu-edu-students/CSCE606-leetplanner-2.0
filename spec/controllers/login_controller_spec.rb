require 'rails_helper'

RSpec.describe LoginController, type: :controller do
  describe 'GET #index' do
    context 'when user is not logged in' do
      it 'renders the login page' do
        get :index
        expect(response).to render_template(:index)
        expect(response).to have_http_status(:ok)
      end

      it 'does not redirect' do
        get :index
        expect(response).not_to be_redirect
      end
    end

    context 'when user is already logged in' do
      let(:user) { create(:user) }

      before do
        # Simulate user being logged in by setting session
        allow(controller).to receive(:current_user).and_return(user)
      end

      it 'redirects to dashboard' do
        get :index
        expect(response).to redirect_to(dashboard_path)
      end

      it 'does not render the login template' do
        get :index
        expect(response).not_to render_template(:index)
      end

      it 'returns redirect status' do
        get :index
        expect(response).to have_http_status(:found)
      end
    end

    context 'authentication requirements' do
      it 'skips authentication for the index action' do
        # This test verifies that skip_before_action is working
        expect(controller).not_to receive(:authenticate_user!)
        get :index
      end
    end

    context 'when current_user returns nil' do
      before do
        allow(controller).to receive(:current_user).and_return(nil)
      end

      it 'renders the login page' do
        get :index
        expect(response).to render_template(:index)
      end
    end

    context 'when current_user returns false' do
      before do
        allow(controller).to receive(:current_user).and_return(false)
      end

      it 'renders the login page' do
        get :index
        expect(response).to render_template(:index)
      end
    end

    context 'response headers and content type' do
      it 'returns HTML content type' do
        get :index
        expect(response.content_type).to include('text/html')
      end
    end
  end
end