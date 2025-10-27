# Controller for handling user login page display
# Shows login page or redirects authenticated users to dashboard
class LoginController < ApplicationController
  # Skip authentication requirement for login page access
  skip_before_action :authenticate_user!

  # GET /login
  # Display login page or redirect if user is already authenticated
  def index
    if current_user
      # User is already logged in, redirect to dashboard
      redirect_to dashboard_path
    else
      # User is not logged in, show login page
      render :index
    end
  end

  # POST /login/dev_bypass (development only)
  # Create a development user session without OAuth
  # This method only works when ENABLE_DEV_LOGIN=true in environment
  def dev_bypass
    # Triple security check: environment, Rails env, and explicit flag
    unless Rails.env.development? && ENV['ENABLE_DEV_LOGIN'] == 'true'
      redirect_to(root_path, alert: "Development login not available") and return
    end

    # Create or find a development user
    user = User.find_or_create_by(email: "dev@tamu.edu") do |u|
      u.netid = "dev"
      u.first_name = "Development"
      u.last_name = "User"
      u.last_login_at = Time.current
    end

    user.update(last_login_at: Time.current)

    # Set session data
    session[:user_id] = user.id
    session[:user_email] = user.email
    session[:user_first_name] = user.first_name

    redirect_to dashboard_path, notice: "Development login successful"
  end
end
