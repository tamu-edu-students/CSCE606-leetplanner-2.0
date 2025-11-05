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

  describe 'POST #dev_bypass' do
    context 'when in development environment with flag enabled' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))
        allow(ENV).to receive(:[]).with('ENABLE_DEV_LOGIN').and_return('true')
      end

      context 'when development user does not exist' do
        it 'creates a new development user' do
          expect {
            post :dev_bypass
          }.to change(User, :count).by(1)
        end

        it 'creates user with correct attributes' do
          post :dev_bypass
          user = User.find_by(email: 'dev@tamu.edu')
          expect(user.netid).to eq('dev')
          expect(user.first_name).to eq('Development')
          expect(user.last_name).to eq('User')
          expect(user.last_login_at).to be_present
        end

        it 'sets session variables' do
          post :dev_bypass
          user = User.find_by(email: 'dev@tamu.edu')
          expect(session[:user_id]).to eq(user.id)
          expect(session[:user_email]).to eq(user.email)
          expect(session[:user_first_name]).to eq(user.first_name)
        end

        it 'redirects to dashboard with success message' do
          post :dev_bypass
          expect(response).to redirect_to(dashboard_path)
          expect(flash[:notice]).to eq('Development login successful')
        end
      end

      context 'when development user already exists' do
        let!(:existing_dev_user) { create(:user, email: 'dev@tamu.edu', netid: 'dev') }

        it 'does not create a new user' do
          expect {
            post :dev_bypass
          }.not_to change(User, :count)
        end

        it 'updates last_login_at' do
          existing_dev_user.update(last_login_at: 1.hour.ago)
          old_login_time = existing_dev_user.last_login_at
          travel_to 1.hour.from_now do
            post :dev_bypass
            existing_dev_user.reload
            expect(existing_dev_user.last_login_at).to be > old_login_time
          end
        end

        it 'sets session for existing user' do
          post :dev_bypass
          expect(session[:user_id]).to eq(existing_dev_user.id)
          expect(session[:user_email]).to eq(existing_dev_user.email)
          expect(session[:user_first_name]).to eq(existing_dev_user.first_name)
        end
      end
    end

    context 'when not in development environment' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
        allow(ENV).to receive(:[]).with('ENABLE_DEV_LOGIN').and_return('true')
      end

      it 'redirects to root with error message' do
        post :dev_bypass
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Development login not available')
      end

      it 'does not create any users' do
        expect {
          post :dev_bypass
        }.not_to change(User, :count)
      end

      it 'does not set session variables' do
        post :dev_bypass
        expect(session[:user_id]).to be_nil
        expect(session[:user_email]).to be_nil
        expect(session[:user_first_name]).to be_nil
      end
    end

    context 'when development flag is disabled' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))
        allow(ENV).to receive(:[]).with('ENABLE_DEV_LOGIN').and_return('false')
      end

      it 'redirects to root with error message' do
        post :dev_bypass
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Development login not available')
      end
    end

    context 'when development flag is not set' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))
        allow(ENV).to receive(:[]).with('ENABLE_DEV_LOGIN').and_return(nil)
      end

      it 'redirects to root with error message' do
        post :dev_bypass
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Development login not available')
      end
    end
  end
end
