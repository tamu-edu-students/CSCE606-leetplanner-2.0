# # Use database_cleaner or similar in your env.rb
# # Assumes the presence of FactoryBot
#
# # --- Background ---
#
# # Given("I am a logged-in user") do
# #   # This helper would be in your features/support/env.rb or similar
# # It needs to create a user and log them in.
# # For Devise, it's:
# # @current_user = FactoryBot.create(:user)
# # login_as(@current_user, scope: :user)
# #
# # For a simple session-based login in tests:
# #   # page.driver.set_cookie('user_id', @current_user.id) # Example
# # end
# #
# # REMOVED this step definition because it is ambiguous.
# # It conflicts with "features/step_definitions/navigation_steps.rb:3".
# # Please ensure your step in 'navigation_steps.rb' correctly sets the
# # '@current_user' instance variable, as the other steps in this file depend on it.
#
# # --- Setup Steps (Given) ---
#
# Given("I am on the new lobby page") do
#   visit new_lobby_path
# end
#
# Given("I am the owner of a lobby named {string}") do |name|
#   @lobby = FactoryBot.create(:lobby, name: name, owner: @current_user)
#   FactoryBot.create(:lobby_member, lobby: @lobby, user: @current_user)
# end
#
# Given("there is a lobby named {string}") do |name|
#   @other_user = FactoryBot.create(:user, email: "other@example.com")
#   @lobby = FactoryBot.create(:lobby, name: name, owner: @other_user)
#   FactoryBot.create(:lobby_member, lobby: @lobby, user: @other_user)
# end
#
# Given("that lobby has other members") do
#   @other_member = FactoryBot.create(:user, email: "member@example.com")
#   FactoryBot.create(:lobby_member, lobby: @lobby, user: @other_member)
#   @lobby_member_ids = @lobby.lobby_members.pluck(:id)
# end
#
# # --- Action Steps (When) ---
#
# When("I fill in {string} with {string}") do |field, value|
#   fill_in field, with: value
# end
#
# When("I press {string}") do |button_name|
#   click_button button_name
# end
#
# When("I click {string}") do |link_name|
#   # This assumes a link or button. You might need to make this more robust
#   # e.g., finding it by a data attribute.
#   # Using `first` to be resilient if 'Destroy' appears multiple times.
#   first(:link_or_button, link_name).click
# end
#
# When("I go to the edit page for {string}") do |name|
#   lobby = Lobby.find_by!(name: name)
#   visit edit_lobby_path(lobby)
# end
#
# When("I go to the page for {string}") do |name|
#   lobby = Lobby.find_by!(name: name)
#   visit lobby_path(lobby)
# end
#
# When("I try to destroy the lobby {string}") do |name|
#   # This step simulates a non-owner trying to bypass the UI
#   # (where the destroy button should be hidden)
#   lobby = Lobby.find_by!(name: name)
#   # Use page.driver to send a DELETE request
#   page.driver.delete(lobby_path(lobby))
# end
#
# # --- API Steps ---
#
# When("I send a POST request to {string} with:") do |path, body|
#   headers = { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }
#   page.driver.post(path, body, headers)
# end
#
# When("I send a DELETE request to the path for {string}") do |name|
#   lobby = Lobby.find_by!(name: name)
#   path = lobby_path(lobby, format: :json)
#   headers = { "ACCEPT" => "application/json" }
#   page.driver.delete(path, {}, headers)
# end
#
# # --- Assertion Steps (Then) ---
#
# Then("I should be on the page for {string}") do |name|
#   lobby = Lobby.find_by!(name: name)
#   expect(current_path).to eq(lobby_path(lobby))
# end
#
# Then("I should be on the lobbies page") do
#   expect(current_path).to eq(lobbies_path)
# end
#
# Then("I should see {string}") do |content|
#   expect(page).to have_content(content)
# end
#
# Then("I should be a member of {string}") do |name|
#   lobby = Lobby.find_by!(name: name)
#   expect(lobby.users).to include(@current_user)
# end
#
# Then("{string} should be owned by me") do |name|
#   lobby = Lobby.find_by!(name: name)
#   expect(lobby.owner).to eq(@current_user)
# end
#
# Then("the owner of {string} should not be me") do |name|
#   lobby = Lobby.find_by!(name: name)
#   expect(lobby.owner).not_to eq(@current_user)
# end
#
# Then("the lobby {string} should not exist") do |name|
#   expect(Lobby.find_by(name: name)).to be_nil
# end
#
# Then("the lobby {string} should still exist") do |name|
#   expect(Lobby.find_by(name: name)).not_to be_nil
# end
#
# Then("the members of {string} should be removed") do |name|
#   # This uses the @lobby_member_ids saved in the 'Given' step
#   expect(LobbyMember.where(id: @lobby_member_ids)).to be_empty
# end
#
# # --- API Assertion Steps ---
#
# Then("the JSON response status should be {int}") do |status|
#   expect(page.driver.status_code).to eq(status)
# end
#
# Then("the JSON response should have a(n) {string} of {string}") do |key, value|
#   json = JSON.parse(page.driver.browser.source)
#   expect(json[key]).to eq(value)
# end
#
# Then("the lobby {string} should be owned by me") do |name|
#   lobby = Lobby.find_by!(name: name)
#   expect(lobby.owner).to eq(@current_user)
# end
