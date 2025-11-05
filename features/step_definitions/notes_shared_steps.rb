# This file provides the Ruby code to execute the steps in lobby_notes.feature.
# You will need to adapt this to your application's setup (Factories, login, etc.)

# --- Given Steps (Setup) ---

Given("a lobby exists, owned by {string}") do |user_name|
  # Store users in an instance variable for retrieval in other steps
  @users ||= {}
  # FIX: Don't assume the factory takes a 'name' attribute.
  # The user_name is just a key for the @users hash.
  @users[user_name] = FactoryBot.create(:user)
  @lobby = FactoryBot.create(:lobby, owner: @users[user_name])
end

Given("{string} is a member of the lobby with edit permissions") do |user_name|
  @users ||= {}
  # FIX: Don't assume the factory takes a 'name' attribute.
  @users[user_name] = FactoryBot.create(:user)
  FactoryBot.create(:lobby_member, lobby: @lobby, user: @users[user_name], can_edit_notes: true)
end

Given("{string} is a member of the lobby without edit permissions") do |user_name|
  @users ||= {}
  # FIX: Don't assume the factory takes a 'name' attribute.
  @users[user_name] = FactoryBot.create(:user)
  FactoryBot.create(:lobby_member, lobby: @lobby, user: @users[user_name], can_edit_notes: false)
end

Given("{string} is an authenticated user who is not a member of the lobby") do |user_name|
  @users ||= {}
  # FIX: Don't assume the factory takes a 'name' attribute.
  @users[user_name] = FactoryBot.create(:user)
end

Given("the lobby does not have a note") do
  @lobby.note.destroy if @lobby.note
end

Given("the lobby has a note with content {string}") do |content|
  FactoryBot.create(:note, lobby: @lobby, user: @lobby.owner, content: content)
end

Given("the lobby has a note") do
  FactoryBot.create(:note, lobby: @lobby, user: @lobby.owner, content: "Some default content")
end

#
# FIX: Removed the ambiguous "I am logged in as {string}" step.
# This step is already defined in 'features/step_definitions/lobby_steps.rb'
# and having it in two places causes an Ambiguous match error.
#
# Given("I am logged in as {string}") do |user_name|
#   @current_user = @users[user_name]
#   #
#   # This is the part you MUST adapt.
#   # This is a common way to stub login in Cucumber for Rack::Test
#   # If you're using Capybara with Selenium, you'll need to fill in the login form.
#   #
#   # Example for Capybara:
#   #   visit login_path
#   #   fill_in "Email", with: @current_user.email
#   #   fill_in "Password", with: @current_user.password # (or 'password' if using a standard factory)
#   #   click_button "Log In"
#   #
#   # Example for stubbing (if not using Capybara, e.g. controller specs logic in features):
#   # We'll use a simple login stubbing method.
#   ApplicationController.any_instance.stub(:current_user).and_return(@current_user)
# end

# --- When Steps (Actions) ---

When("I go to the lobby's note page") do
  visit lobby_note_path(@lobby)
end

When("I go to the lobby's edit note page") do
  visit edit_lobby_note_path(@lobby)
end

# FIX: Add the missing step definition from the feature file
When("I go to the edit lobby note page") do
  # This step was missing the "lobby's" part in one scenario.
  visit edit_lobby_note_path(@lobby)
end

When("I try to go to the edit lobby note page") do
  visit edit_lobby_note_path(@lobby)
end

When("I fill in the note content with {string}") do |content|
  # Assuming your text area has a label "Note Content" or id "note_content"
  fill_in "note_content", with: content
end

When("I click {string}") do |button_text|
  click_button button_text
end

# --- Then Steps (Assertions) ---

Then("I should be on the lobby note page") do
  expect(current_path).to eq lobby_note_path(@lobby)
end

Then("I should be on the edit lobby note page") do
  expect(current_path).to eq edit_lobby_note_path(@lobby)
end

Then("I should be redirected to the lobby's main page") do
  expect(current_path).to eq lobby_path(@lobby)
end

#
# FIX: Removed the ambiguous "I should see {string}" step.
# This step is already defined in 'features/step_definitions/web_steps.rb'
# and having it in two places causes an Ambiguous match error.
#
# Then("I should see {string}") do |text|
#   expect(page).to have_content(text)
# end

Then("I should not see a button to {string}") do |button_text|
  expect(page).not_to have_button(button_text)
end

Then("I should still be on the edit lobby note page") do
  # A failed update re-renders :edit, which keeps the URL as /notes
  # but the controller is `notes` and action `update`.
  # This assertion is a bit tricky. A good-enough check:
  expect(page).to have_button("Save Note")
end
