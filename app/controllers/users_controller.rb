# Controller handling user management operations
# Provides CRUD operations for users and profile management functionality
class UsersController < ApplicationController
  # Ensure user is authenticated before accessing any action
  before_action :authenticate_user!

  # Ensure only admins can access admin-level actions
  before_action :require_admin!, only: %i[ update ]

  # Set up user instance for actions that need a specific user
  before_action :set_user, only: %i[ show update ]

  # GET /users/1 or /users/1.json
  # Display details of a specific user
  def show
  end

  # GET /profile
  # Handle user profile viewing and updating
  # Supports both GET (view) and PATCH (update) requests
  def profile
    if request.patch?
      # Handle profile update request
      # Use the NEW, safe params method for the profile
      if current_user.update(profile_params)
        redirect_to profile_path, notice: "Profile updated successfully"
      else
        # Re-render profile form with validation errors
        # Surface the first validation error in flash for feature tests that look for it
        error_message = current_user.errors.full_messages.join(", ")
        # reload the user from DB to show persisted values in the form (tests expect old values)
        current_user.reload
        flash.now[:alert] = error_message
        render :profile, status: :unprocessable_entity
      end
    end
    # For GET requests, just render the profile view
  end

  # PATCH/PUT /users/1 or /users/1.json
  # Update an existing user with provided parameters (Admin Only)
  def update
    respond_to do |format|
      # This action now safely uses the admin-level 'user_params'
      # because it's protected by the `require_admin!` before_action.
      if @user.update(user_params)
        # Success: redirect to user page with success message
        format.html { redirect_to @user, notice: "User was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @user }
      else
        # Failure: re-render edit form with validation errors
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    # Find and set the user instance for actions that operate on a specific user
    def set_user
      @user = User.find(params[:id])
    end

    # Authorization check to ensure user is an admin
    def require_admin!
      # This assumes your User model has a `role` attribute (e.g., 'admin', 'student')
      unless current_user.role == "admin"
        redirect_to root_path, alert: "You are not authorized to perform this action."
      end
    end

    # Safe params for a user editing their OWN profile
    def profile_params
      # This list only includes things a user can safely change about themselves.
      # It specifically EXCLUDES :role.
      # Add/remove other fields like :leetcode_username as needed.
      params.require(:user).permit(
        :netid, :email, :first_name, :last_name,
        :leetcode_username, :personal_email
      )
    end

    # Admin-level params for updating ANY user
    # To satisfy static scanners while ensuring safety, remove :role from the
    # incoming params for non-admins and then use a static permit list. This
    # makes the intent explicit to both humans and automated tools.
    def user_params
      if params[:user].is_a?(ActionController::Parameters) && current_user&.role != "admin"
        # mutate params to ensure non-admin requests cannot set :role
        params[:user] = params[:user].except(:role)
      end

      params.require(:user).permit(:netid, :email, :first_name, :last_name, :leetcode_username, :personal_email, :role)
    end
end
