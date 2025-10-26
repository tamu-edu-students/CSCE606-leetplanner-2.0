class TestHelpersController < ApplicationController
  # This controller is only used in test environment to assist feature tests.
  # It provides a deterministic endpoint to clear the server-side session.

  # Skip CSRF for test helper endpoints since tests may call via GET/POST
  skip_before_action :verify_authenticity_token
  # These endpoints are intended for test-only usage and must not require
  # normal application authentication.
  skip_before_action :authenticate_user!

  def clear_session
    reset_session
    head :ok
  end

  # Clear the session and set a flash alert, then redirect to the login page.
  # Useful for feature tests that expect the login page to show an expired-session message.
  def clear_session_with_alert
    reset_session
    flash[:alert] = "Your session expired. Please log in again."
    redirect_to root_path
  end

  # Clear the manual timer key from the session
  def clear_timer
    session[:timer_ends_at] = nil
    head :ok
  end

  # Set a manual timer in the server session for test scenarios
  def set_timer
    minutes = params[:minutes].to_i
    if minutes > 0
      session[:timer_ends_at] = (Time.now.utc + minutes.minutes).iso8601
    else
      session.delete(:timer_ends_at)
    end
    redirect_to dashboard_path
  end

  # Deterministically sign in as a user for feature tests.
  # Usage: /test/login_as?email=someone@tamu.edu
  def login_as
    email = params[:email].to_s.strip
    return head :bad_request if email.blank?

    user = User.find_or_initialize_by(email: email)
    user.netid ||= email.split('@').first
    user.first_name ||= 'Test'
    user.last_name  ||= 'User'
    user.last_login_at = Time.current
    user.save! if user.changed?

    # Mirror what SessionsController#create sets in the session
    session[:user_id] = user.id
    session[:user_email] = user.email
    session[:user_first_name] = user.first_name

    redirect_to dashboard_path
  end
end
