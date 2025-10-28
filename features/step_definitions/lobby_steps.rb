# Reusable helper step for a generic logged-in user
Given("I am logged in") do
  @current_user ||= FactoryBot.create(:user)

  # Simulate the OmniAuth callback
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
    provider: 'google_oauth2',
    uid: SecureRandom.hex(4),
    info: { email: @current_user.email, first_name: @current_user.first_name, last_name: @current_user.last_name }
  })
  visit '/auth/google_oauth2/callback'
end

# Reusable helper for logging in a specific user
Given("I am logged in as {string}") do |name|
  first_name, last_name = name.split(' ', 2)
  last_name ||= 'User' # Default last name
  @current_user = FactoryBot.create(:user, first_name: first_name, last_name: last_name)
  
  # Use the same OmniAuth mock
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
    provider: 'google_oauth2',
    uid: SecureRandom.hex(4),
    info: { email: @current_user.email, first_name: @current_user.first_name, last_name: @current_user.last_name }
  })
  visit '/auth/google_oauth2/callback'
end

# Simplified step that calls the helper
Given("I am a registered user") do
  step "I am logged in"
end

##
## Join Lobby Steps
##

Given("a lobby named {string} exists") do |lobby_name|
  @lobby = FactoryBot.create(:lobby, name: lobby_name)
end

Given("I am a registered user named {string} who is not in the lobby") do |name|
  step "I am logged in as \"#{name}\""
end

When("I attempt to join the lobby with the correct lobby code") do
  visit lobbies_path
  fill_in 'lobby_code', with: @lobby.lobby_code
  click_button 'Join'
end

When("I attempt to join the lobby with an invalid lobby code") do
  visit lobbies_path
  fill_in 'lobby_code', with: 'INVALID'
  click_button 'Join'
end

Given("I am a registered user and a member of the {string} lobby") do |lobby_name|
  step "I am logged in"
  @lobby = FactoryBot.create(:lobby, name: lobby_name)
  FactoryBot.create(:lobby_member, lobby: @lobby, user: @current_user)
end

When("I attempt to join the lobby with the correct lobby code again") do
  visit lobbies_path
  fill_in 'lobby_code', with: @lobby.lobby_code
  click_button 'Join'
end

Then("I should be on the page for {string}") do |lobby_name|
  lobby = Lobby.find_by!(name: lobby_name)
  expect(current_path).to eq(lobby_path(lobby))
  expect(page).to have_content(lobby_name)
end

Then("I should see my name {string} in the participant list") do |name|
  expect(page).to have_content(name)
end

Then("I should see an error message {string}") do |message|
  expect(page).to have_selector('.flash-alert', text: message)
end

Then("I should be on the lobbies page") do
  expect(current_path).to eq(lobbies_path)
end

##
## Leave Lobby Steps
##

Given("I am logged in as {string} and am in a lobby") do |name|
  step "I am logged in as \"#{name}\""
  owner = FactoryBot.create(:user)
  @lobby = FactoryBot.create(:lobby, owner: owner)
  FactoryBot.create(:lobby_member, lobby: @lobby, user: owner)
  FactoryBot.create(:lobby_member, lobby: @lobby, user: @current_user)
  visit lobby_path(@lobby)
end

Then("I should be redirected to the lobbies page") do
  expect(current_path).to eq(lobbies_path)
end

Then("I should see a success message {string}") do |message|
  expect(page).to have_selector('.flash-success', text: message)
end

##
## Manage Permissions Steps
##

Given("I am the owner of a lobby with {string} as a participant") do |participant_name|
  @owner = FactoryBot.create(:user)
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
    provider: 'google_oauth2',
    uid: SecureRandom.hex(4),
    info: { email: @owner.email, first_name: @owner.first_name, last_name: @owner.last_name }
  })
  visit '/auth/google_oauth2/callback'
  @current_user = @owner

  participant_first, participant_last = participant_name.split(' ', 2)
  participant_last ||= 'User'
  @participant = FactoryBot.create(:user, first_name: participant_first, last_name: participant_last)
  @lobby = FactoryBot.create(:lobby, owner: @owner)
  FactoryBot.create(:lobby_member, lobby: @lobby, user: @owner)
  FactoryBot.create(:lobby_member, lobby: @lobby, user: @participant)

  visit lobby_path(@lobby)
end

Given("{string} does not have permission to draw") do |participant_name|
  user = User.find_by!(first_name: participant_name.split.first)
  member = @lobby.lobby_members.find_by!(user: user)
  member.update!(can_draw: false)
end

When("I check the {string} box for {string} and click {string}") do |checkbox_label, participant_name, button_text|
  # Find the table row for the participant, then check the box by its label
  find('tr', text: participant_name).check(checkbox_label)
  click_button button_text
end

Then("the {string} box for {string} should be checked") do |checkbox_label, participant_name|
  expect(find('tr', text: participant_name)).to have_checked_field(checkbox_label)
end

Given("{string} is the owner of a lobby") do |owner_name|
  first_name, last_name = owner_name.split(' ', 2)
  last_name ||= 'User' # Default last name
  owner = FactoryBot.create(:user, first_name: first_name, last_name: last_name)
  @lobby = FactoryBot.create(:lobby, owner: owner)
  FactoryBot.create(:lobby_member, lobby: @lobby, user: owner)
end

Given("I am logged in as {string}, a participant in that lobby") do |participant_name|
  step "I am logged in as \"#{participant_name}\""
  FactoryBot.create(:lobby_member, lobby: @lobby, user: @current_user)
end

When("I visit the lobby page") do
  visit lobby_path(@lobby)
end

Then("I should not see the {string} table") do |table_name|
  expect(page).to have_no_selector('table.permissions-table')
end

##
## View Participant List Steps
##

Given("a lobby exists with owner {string} and participant {string}") do |owner_name, participant_name|
  owner = FactoryBot.create(:user, first_name: owner_name)
  participant = FactoryBot.create(:user, first_name: participant_name)
  @lobby = FactoryBot.create(:lobby, owner: owner)
  FactoryBot.create(:lobby_member, lobby: @lobby, user: owner)
  FactoryBot.create(:lobby_member, lobby: @lobby, user: participant)
end

Given("I am logged in as {string} and am viewing the lobby") do |name|
  first_name = name.split.first
  @current_user = User.find_by!(first_name: first_name)

  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
    provider: 'google_oauth2',
    uid: SecureRandom.hex(4),
    info: { 
      email: @current_user.email, 
      first_name: @current_user.first_name, 
      last_name: @current_user.last_name 
    }
  })
  visit '/auth/google_oauth2/callback'
  visit lobby_path(@lobby)
end

Then("I should see {string} in the list") do |name|
  within('.lobby-members') do
    expect(page).to have_content(name)
  end
end