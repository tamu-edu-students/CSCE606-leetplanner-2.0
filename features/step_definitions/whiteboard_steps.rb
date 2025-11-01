Given('a lobby exists that I own') do
  @user ||= User.first || create(:user)
  @lobby = create(:lobby, owner: @user)
  visit lobby_path(@lobby)
end

When('I add a rectangle to the whiteboard') do
  within('.whiteboard-basic-controls') do
    click_button('⬜ Rectangle')
  end
end

When('I update the whiteboard notes to {string}') do |text|
  fill_in('whiteboard_notes', with: text)
  click_button('Save Notes')
end

Then('I should see a success message') do
  expect(page).to have_css('.flash-success, .notice', text: /Added rectangle/i)
end

Then('I should see {string} on the lobby page') do |text|
  expect(page).to have_content(text)
end
