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
end
