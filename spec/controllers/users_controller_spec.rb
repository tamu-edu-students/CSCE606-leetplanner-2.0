require 'rails_helper'

RSpec.describe UsersController, type: :controller do

  # --- Setup ---
  # Create a valid User based on your user.rb model
  let!(:user) { User.create!(
    netid: "specuser",
    email: "specuser@example.com",
    first_name: "Spec",
    last_name: "User"
  ) }
  
  # Valid/invalid attributes for update tests
  let(:valid_attributes) { { first_name: "NewFirstName" } }
  let(:invalid_attributes) { { email: "" } } # Fails validation

  context "when user is authenticated" do
    before do
      # "Log in" the user by setting the session
      session[:user_id] = user.id
    end

    describe "GET #show" do
      it "succeeds and assigns the correct user" do
        get :show, params: { id: user.id }
        
        # This covers the `set_user` private method
        expect(assigns(:user)).to eq(user)
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET #profile" do
      it "succeeds and renders the profile template" do
        get :profile
        
        # This covers the `else` path of `if request.patch?`
        expect(response).to render_template(:profile)
        expect(response).to have_http_status(:success)
      end
    end

    describe "PATCH #profile" do
      context "with valid parameters" do
        it "updates the current user and redirects" do
          patch :profile, params: { user: valid_attributes }
          
          # This covers lines 21-22
          expect(user.reload.first_name).to eq("NewFirstName")
          expect(response).to redirect_to(profile_path)
          expect(flash[:notice]).to eq("Profile updated successfully")
        end
      end

      context "with invalid parameters" do
        it "re-renders the profile with an alert" do
          patch :profile, params: { user: invalid_attributes }
          
          # This covers lines 26-30
          expect(response).to render_template(:profile)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(flash.now[:alert]).to be_present
        end
      end
    end

    describe "PATCH #update" do
      context "with valid parameters" do
        it "updates the user and redirects (HTML)" do
          patch :update, params: { id: user.id, user: valid_attributes }
          
          # This covers line 41
          expect(user.reload.first_name).to eq("NewFirstName")
          expect(response).to redirect_to(user_path(user))
        end

        it "updates the user and renders :show (JSON)" do
          patch :update, params: { id: user.id, user: valid_attributes }, as: :json
          
          # This covers line 42
          expect(user.reload.first_name).to eq("NewFirstName")
          expect(response).to have_http_status(:ok)
        end
      end

      context "with invalid parameters" do
        it "re-renders the edit template (HTML)" do
          patch :update, params: { id: user.id, user: invalid_attributes }
          
          # This covers line 46
          expect(response).to render_template(:edit)
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "returns errors as JSON (JSON)" do
          patch :update, params: { id: user.id, user: invalid_attributes }, as: :json
          
          # This covers line 47
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  context "when user is not authenticated" do
    before do
      session[:user_id] = nil
    end

    it "redirects GET #show to root" do
      get :show, params: { id: user.id }
      expect(response).to redirect_to(root_path)
    end
    
    it "redirects GET #profile to root" do
      get :profile
      expect(response).to redirect_to(root_path)
    end

    it "redirects PATCH #profile to root" do
      patch :profile, params: { user: valid_attributes }
      expect(response).to redirect_to(root_path)
    end

    it "redirects PATCH #update to root" do
      patch :update, params: { id: user.id, user: valid_attributes }
      expect(response).to redirect_to(root_path)
    end
  end
end
