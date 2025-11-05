require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  # Create an anonymous controller that inherits from ApplicationController for testing
  controller(ApplicationController) do
    def index
      render plain: 'success'
    end

    def protected_action
      authenticate_user!
      render plain: 'authenticated'
    end
  end

  # Set up routes for the anonymous controller
  before do
    routes.draw do
      get 'index' => 'anonymous#index'
      get 'protected_action' => 'anonymous#protected_action'
    end
  end
  
  after do
    # Restore full application routes so subsequent specs (lobbies, whiteboards, etc.) have their path helpers.
    Rails.application.reload_routes!
  end

  let(:user) { create(:user) }

  describe '#authenticate_user!' do
    context 'when user is not logged in' do
      before { session[:user_id] = nil }

      context 'for regular HTTP requests' do
        it 'redirects to root path' do
          get :protected_action
          expect(response).to redirect_to('/')
        end

        it 'sets flash alert message' do
          get :protected_action
          expect(flash[:alert]).to eq("You must be logged in to access this page.")
        end
      end

      context 'for AJAX requests' do
        it 'returns JSON error response with 401 status' do
          request.headers['HTTP_X_REQUESTED_WITH'] = 'XMLHttpRequest'
          get :protected_action

          expect(response).to have_http_status(:unauthorized)
          expect(JSON.parse(response.body)).to eq({ 'error' => 'Authentication required' })
        end
      end

      context 'for JSON requests' do
        it 'returns JSON error response with 401 status' do
          get :protected_action, format: :json

          expect(response).to have_http_status(:unauthorized)
          expect(JSON.parse(response.body)).to eq({ 'error' => 'Authentication required' })
        end
      end
    end

    context 'when user is logged in' do
      before { session[:user_id] = user.id }

      it 'allows access to protected actions' do
        get :protected_action
        expect(response).to have_http_status(:success)
        expect(response.body).to eq('authenticated')
      end

      it 'does not redirect or show error' do
        get :protected_action
        expect(response).not_to redirect_to('/')
        expect(flash[:alert]).to be_nil
      end
    end
  end

  describe '#current_user' do
    context 'when user_id is in session' do
      before { session[:user_id] = user.id }

      it 'returns the user object' do
        expect(controller.send(:current_user)).to eq(user)
      end

      it 'memoizes the user object to avoid multiple database queries' do
        expect(User).to receive(:find).with(user.id).once.and_return(user)

        # Call current_user multiple times
        controller.send(:current_user)
        controller.send(:current_user)
        controller.send(:current_user)
      end
    end

    context 'when user_id is not in session' do
      before { session[:user_id] = nil }

      it 'returns nil' do
        expect(controller.send(:current_user)).to be_nil
      end
    end

    context 'when user_id in session is invalid' do
      before { session[:user_id] = 99999 }

      it 'raises ActiveRecord::RecordNotFound' do
        expect { controller.send(:current_user) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when session is empty' do
      before { session.clear }

      it 'returns nil' do
        expect(controller.send(:current_user)).to be_nil
      end
    end
  end

  describe '#user_signed_in?' do
    context 'when user is signed in' do
      before { session[:user_id] = user.id }

      it 'returns true' do
        expect(controller.send(:user_signed_in?)).to be true
      end
    end

    context 'when user is not signed in' do
      before { session[:user_id] = nil }

      it 'returns false' do
        expect(controller.send(:user_signed_in?)).to be false
      end
    end

    context 'when current_user is nil' do
      before do
        session[:user_id] = nil
        allow(controller).to receive(:current_user).and_return(nil)
      end

      it 'returns false' do
        expect(controller.send(:user_signed_in?)).to be false
      end
    end
  end

  describe 'helper methods' do
    it 'makes current_user available as a helper method' do
      expect(controller._helper_methods).to include(:current_user)
    end

    it 'makes user_signed_in? available as a helper method' do
      expect(controller._helper_methods).to include(:user_signed_in?)
    end
  end

  describe 'before_action callbacks' do
    it 'includes authenticate_user! as a before_action' do
      expect(ApplicationController._process_action_callbacks.any? do |callback|
        callback.filter == :authenticate_user! && callback.kind == :before
      end).to be true
    end
  end

  describe 'CSRF protection' do
    it 'protects from forgery with exception' do
      expect(ApplicationController.forgery_protection_strategy).to eq(ActionController::RequestForgeryProtection::ProtectionMethods::Exception)
    end
  end

  describe 'browser compatibility' do
    it 'allows modern browsers only' do
      # Test that browser restriction is in place - Rails adds a proc for allow_browser
      filters = ApplicationController._process_action_callbacks.map(&:filter)
      has_browser_filter = filters.any? { |filter| filter.is_a?(Proc) }
      expect(has_browser_filter).to be true
    end
  end

  describe 'edge cases and error handling' do
    context 'when database connection is lost' do
      before do
        session[:user_id] = user.id
        allow(User).to receive(:find).and_raise(ActiveRecord::ConnectionNotEstablished)
      end

      it 'handles database connection errors gracefully' do
        expect { controller.send(:current_user) }.to raise_error(ActiveRecord::ConnectionNotEstablished)
      end
    end

    context 'when session is corrupted' do
      before do
        # Simulate corrupted session data
        session[:user_id] = "invalid_id"
      end

      it 'handles invalid session data' do
        expect { controller.send(:current_user) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'security considerations' do
    context 'when user account is deleted but session persists' do
      before do
        session[:user_id] = user.id
        user.destroy
      end

      it 'raises RecordNotFound when trying to access deleted user' do
        expect { controller.send(:current_user) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'session hijacking simulation' do
      let(:other_user) { create(:user) }

      before { session[:user_id] = user.id }

      it 'maintains user identity throughout request due to memoization' do
        initial_user = controller.send(:current_user)
        # Simulate session change mid-request (shouldn't happen in practice due to memoization)
        session[:user_id] = other_user.id

        # Due to memoization, should still return the original user
        expect(controller.send(:current_user)).to eq(initial_user)
      end
    end
  end

  describe 'authentication bypass scenarios' do
    controller(ApplicationController) do
      skip_before_action :authenticate_user!, only: [ :skip_auth_action ]

      def skip_auth_action
        render plain: 'no auth needed'
      end
    end

    context 'when action skips authentication' do
      it 'allows access without authentication' do
        routes.draw { get 'skip_auth_action' => 'anonymous#skip_auth_action' }
        session[:user_id] = nil
        get :skip_auth_action
        expect(response).to have_http_status(:success)
        expect(response.body).to eq('no auth needed')
      end
    end
  end

  describe 'integration with other controller concerns' do
    context 'CSRF protection' do
      it 'enables CSRF protection' do
        expect(ApplicationController.forgery_protection_strategy).to eq(ActionController::RequestForgeryProtection::ProtectionMethods::Exception)
      end
    end

    context 'before action execution order' do
      it 'executes authenticate_user! before actions' do
        auth_callback = ApplicationController._process_action_callbacks.find { |cb| cb.filter == :authenticate_user! }
        expect(auth_callback).to be_present
        expect(auth_callback.kind).to eq(:before)
      end
    end
  end
end
