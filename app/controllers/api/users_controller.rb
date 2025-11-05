module Api
  class UsersController < ApplicationController
    def profile
      if user_signed_in?
        render json: {
          id: current_user.id,
          name: current_user.full_name,
          first_name: current_user.first_name,
          last_name: current_user.last_name,
          email: current_user.email,
          leetcode_username: current_user.leetcode_username
        }
      else
        render json: { error: "Not signed in" }, status: :unauthorized
      end
    end
  end
end
