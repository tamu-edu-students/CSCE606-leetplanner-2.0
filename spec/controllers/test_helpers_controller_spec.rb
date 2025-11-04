require 'rails_helper'

RSpec.describe TestHelpersController, type: :controller do
  
  before do
    routes.draw do
      # Define the controller's actions
      get 'test/clear_session' => 'test_helpers#clear_session'
      get 'test/clear_session_with_alert' => 'test_helpers#clear_session_with_alert'
      get 'test/clear_timer' => 'test_helpers#clear_timer'
      get 'test/set_timer' => 'test_helpers#set_timer'
      get 'test/login_as' => 'test_helpers#login_as'

      # Define the named routes this controller redirects to
      get 'dashboard' => 'test_helpers#clear_session', as: :dashboard
      root 'test_helpers#clear_session' # Mock root_path
    end
  end

  describe "GET #clear_session" do
    it "clears the session and returns :ok" do
      session[:user_id] = 123 # Set a dummy session
      get :clear_session
      
      expect(session[:user_id]).to be_nil
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET #clear_session_with_alert" do
    it "clears the session, sets a flash, and redirects to root" do
      session[:user_id] = 123
      get :clear_session_with_alert
      
      expect(session[:user_id]).to be_nil
      expect(flash[:alert]).to eq("Your session expired. Please log in again.")
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET #clear_timer" do
    it "clears the timer from the session and returns :ok" do
      session[:timer_ends_at] = Time.now.iso8601
      get :clear_timer
      
      expect(session[:timer_ends_at]).to be_nil
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET #set_timer" do
    # Include TimeHelpers to freeze time for consistent iso8601 comparisons
    include ActiveSupport::Testing::TimeHelpers

    it "sets the timer in the session for positive minutes and redirects" do
      freeze_time do # Freeze time
        get :set_timer, params: { minutes: 15 }
        
        expected_time = (Time.now.utc + 15.minutes).iso8601
        expect(session[:timer_ends_at]).to eq(expected_time)
        expect(response).to redirect_to(dashboard_path)
      end
    end

    it "deletes the timer for zero minutes and redirects" do
      session[:timer_ends_at] = Time.now.iso8601
      get :set_timer, params: { minutes: 0 }
      
      expect(session[:timer_ends_at]).to be_nil
      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe "GET #login_as" do
    it "returns :bad_request if email is blank" do
      get :login_as, params: { email: " " }
      expect(response).to have_http_status(:bad_request)
    end

    context "with an existing user" do
      # Create a valid user based on User model's validations
      let!(:existing_user) { User.create!(
        email: "existing@tamu.edu",
        netid: "existing",
        first_name: "Old",
        last_name: "User"
      ) }

      it "logs in the existing user and updates last_login_at" do
        expect {
          # Also tests that whitespace is stripped from the param
          get :login_as, params: { email: " existing@tamu.edu " }
        }.not_to change(User, :count) # No new user should be created

        expect(session[:user_id]).to eq(existing_user.id)
        expect(session[:user_email]).to eq(existing_user.email)
        expect(session[:user_first_name]).to eq(existing_user.first_name)
        expect(response).to redirect_to(dashboard_path)
        
        # Check that last_login_at was updated
        expect(existing_user.reload.last_login_at).to be_present
      end
    end

    context "with a new user" do
      it "creates a new user with default values and logs them in" do
        expect {
          get :login_as, params: { email: "new@tamu.edu" }
        }.to change(User, :count).by(1) # A new user should be created

        new_user = User.last
        expect(new_user.email).to eq("new@tamu.edu")
        expect(new_user.netid).to eq("new")
        expect(new_user.first_name).to eq("Test")
        expect(new_user.last_name).to eq("User")
        expect(new_user.last_login_at).to be_present

        expect(session[:user_id]).to eq(new_user.id)
        expect(session[:user_email]).to eq(new_user.email)
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end
end
