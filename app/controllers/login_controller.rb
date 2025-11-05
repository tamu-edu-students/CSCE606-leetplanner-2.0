# Controller for handling user login page display
# Shows login page or redirects authenticated users to dashboard
class LoginController < ApplicationController
  # Skip authentication requirement for login page access & dev bypass
  skip_before_action :authenticate_user!, only: %i[index dev_bypass]

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

  # POST /login/dev_bypass
  # Development-only helper to quickly sign in a predefined user.
  def dev_bypass
    unless Rails.env.development? && ENV['ENABLE_DEV_LOGIN'] == 'true'
      flash[:alert] = 'Development login not available'
      redirect_to root_path and return
    end

    user = User.find_by(email: 'dev@tamu.edu')
    if user.nil?
      user = User.create!(
        netid: 'dev',
        email: 'dev@tamu.edu',
        first_name: 'Development',
        last_name: 'User',
        last_login_at: Time.current
      )
    else
      user.update!(last_login_at: Time.current)
    end

    session[:user_id] = user.id
    session[:user_email] = user.email
    session[:user_first_name] = user.first_name

    flash[:notice] = 'Development login successful'
    redirect_to dashboard_path
  end
end
