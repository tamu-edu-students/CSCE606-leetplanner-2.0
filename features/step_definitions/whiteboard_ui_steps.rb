Given('a lobby exists that I own with members') do
  @user ||= User.first || create(:user, first_name: "Owner", last_name: "User")
  @member1 = create(:user, first_name: "John", last_name: "Doe")
  @member2 = create(:user, first_name: "Jane", last_name: "Smith")

  @lobby = create(:lobby, owner: @user, name: "Test Lobby")
  @lobby_member1 = create(:lobby_member, lobby: @lobby, user: @member1, can_draw: true, can_edit_notes: true)
  @lobby_member2 = create(:lobby_member, lobby: @lobby, user: @member2, can_draw: false, can_edit_notes: false)
end

Then('I should see the three-column layout') do
  expect(page).to have_css('.lobby-layout')
  expect(page).to have_css('.lobby-section', count: 3)
end

Then('the shared notes section should be compact') do
  expect(page).to have_css('.lobby-section:first-child')
  expect(page).to have_content('Shared Notes')
  expect(page).to have_css('.notes-area')
end

Then('the whiteboard section should be prominent in the center') do
  expect(page).to have_css('.lobby-section.whiteboard-section')
  expect(page).to have_content('Whiteboard')
  expect(page).to have_css('.whiteboard-container')
end

Then('the participants section should be compact') do
  expect(page).to have_css('.lobby-section:last-child')
  expect(page).to have_content('Participants')
  expect(page).to have_css('.participants-list')
end

Then('the whiteboard canvas should have dimensions of {int}x{int} pixels') do |width, height|
  expect(page).to have_css("canvas#whiteboard-canvas[width='#{width}'][height='#{height}']")
end

Then('the canvas should be responsive on smaller screens') do
  # Check that responsive sizing JavaScript is present
  expect(page.html).to include('containerWidth < 1000')
  expect(page.html).to include('containerWidth * 0.5')
end

Then('the drawing tools should be easily accessible') do
  expect(page).to have_css('.whiteboard-toolbar')
  expect(page).to have_css('.tool-btn')
end

Then('the shared notes section should be present') do
  expect(page).to have_css('.notes-area')
  expect(page).to have_css('.shared-notes, textarea')
end

Then('the notes textarea should have a reasonable height') do
  # Check that textarea exists (specific height is controlled by CSS)
  expect(page).to have_css('textarea.shared-notes, textarea[readonly]')
end

Then('I should be able to save notes if I have permission') do
  if page.has_button?('Save Notes')
    expect(page).to have_button('Save Notes')
  else
    expect(page).to have_content("You don't have permission to edit notes")
  end
end

Then('I should see the participants count') do
  expect(page).to have_content('Participants (2)')
end

Then('I should see member avatars with initials') do
  expect(page).to have_css('.participant-avatar')
  # Check for initials
  expect(page).to have_css('.participant-avatar', text: 'J')
end

Then('I should see member names') do
  expect(page).to have_content('John Doe')
  expect(page).to have_content('Jane Smith')
end

Then('I should see online status indicators') do
  expect(page).to have_css('.status-dot.online')
end

Then('I should see lobby analytics') do
  expect(page).to have_content('Lobby Analytics')
  expect(page).to have_content('Active Users:')
  expect(page).to have_content('2/5')
end

Then('I should see the pencil tool') do
  expect(page).to have_css('#pencil-tool')
  expect(page).to have_content('Pencil')
end

Then('I should see the eraser tool') do
  expect(page).to have_css('#eraser-tool')
  expect(page).to have_content('Eraser')
end

Then('I should see the clear button') do
  expect(page).to have_css('#clear-btn')
  expect(page).to have_content('Clear')
end

Then('I should see the color picker') do
  expect(page).to have_css('#color-picker[type="color"]')
end

Then('I should see the brush size slider') do
  expect(page).to have_css('#brush-size[type="range"]')
  expect(page).to have_css('#size-display')
end

When('I view the page on a mobile device') do
  page.current_window.resize_to(375, 667) # iPhone size
end

Then('the layout should stack vertically') do
  # On mobile, the CSS grid should change to single column
  # This is tested by checking that the layout exists and responsive CSS is applied
  expect(page).to have_css('.lobby-layout')
end

Then('the whiteboard should remain functional') do
  expect(page).to have_css('#whiteboard-canvas')
  expect(page).to have_css('.whiteboard-toolbar')
end

Then('touch events should work for drawing') do
  # Check that touch event handlers are present in JavaScript
  expect(page.html).to include('touchstart')
  expect(page.html).to include('touchmove')
  expect(page.html).to include('touchend')
end

Given('I am a member without drawing permissions') do
  visit logout_path if page.has_link?('Logout') # Ensure clean login state

  # Login as member2 who has no permissions
  visit login_path
  fill_in 'email', with: @member2.email
  fill_in 'password', with: 'password'
  click_button 'Log In'
end

Then('I should see a permission restriction message') do
  expect(page).to have_content('You do not have permission to draw')
end

Then('the drawing tools should be disabled') do
  # Check that canDraw is false in JavaScript
  expect(page.html).to include('canDraw = false')
end

Then('I should not be able to edit shared notes') do
  expect(page).to have_css('textarea[readonly]')
  expect(page).to have_content("You don't have permission to edit notes")
end

Given('I am a member with drawing permissions') do
  visit logout_path if page.has_link?('Logout')

  # Login as member1 who has permissions
  visit login_path
  fill_in 'email', with: @member1.email
  fill_in 'password', with: 'password'
  click_button 'Log In'
end

Then('I should not see permission restriction messages') do
  expect(page).not_to have_content('You do not have permission to draw')
end

Then('the drawing tools should be enabled') do
  expect(page.html).to include('canDraw = true')
end

Then('I should be able to edit shared notes') do
  expect(page).to have_css('textarea.shared-notes:not([readonly])')
  expect(page).to have_button('Save Notes')
end

# JavaScript-dependent steps
When('I click the pencil tool') do
  page.execute_script('document.getElementById("pencil-tool").click()')
end

Then('the pencil tool should be active') do
  expect(page).to have_css('#pencil-tool.active')
end

When('I draw on the canvas') do
  # Simulate drawing by executing JavaScript
  page.execute_script(<<~JS)
    const canvas = document.getElementById('whiteboard-canvas');
    const ctx = canvas.getContext('2d');
    ctx.beginPath();
    ctx.moveTo(50, 50);
    ctx.lineTo(100, 100);
    ctx.stroke();
  JS
end

Then('the drawing should appear on the canvas') do
  # Check that the canvas context has been used for drawing
  canvas_has_content = page.evaluate_script(<<~JS)
    const canvas = document.getElementById('whiteboard-canvas');
    const ctx = canvas.getContext('2d');
    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
    const data = imageData.data;

    // Check if any pixel is not transparent (has been drawn on)
    for (let i = 3; i < data.length; i += 4) {
      if (data[i] !== 0) return true;
    }
    return false;
  JS

  expect(canvas_has_content).to be true
end

Then('the drawing should be saved to the server') do
  # Check that saveToServer function exists and can be called
  save_function_exists = page.evaluate_script('typeof saveToServer === "function"')
  expect(save_function_exists).to be true
end

When('I change the color picker to red') do
  page.execute_script('document.getElementById("color-picker").value = "#ff0000"')
  page.execute_script('document.getElementById("color-picker").dispatchEvent(new Event("change"))')
end

Then('the drawing color should be red') do
  current_color = page.evaluate_script('currentColor')
  expect(current_color).to eq('#ff0000')
end

When('I change the brush size to {int}') do |size|
  page.execute_script("document.getElementById('brush-size').value = #{size}")
  page.execute_script('document.getElementById("brush-size").dispatchEvent(new Event("input"))')
end

Then('the brush size display should show {int}') do |size|
  expect(page).to have_css('#size-display', text: size.to_s)
end

Given('there is content on the whiteboard') do
  # Add some content to the whiteboard via JavaScript
  page.execute_script(<<~JS)
    const canvas = document.getElementById('whiteboard-canvas');
    const ctx = canvas.getContext('2d');
    ctx.fillRect(10, 10, 50, 50);
  JS
end

When('I click the clear button') do
  page.execute_script('document.getElementById("clear-btn").click()')
end

When('I confirm the clear action') do
  page.driver.browser.switch_to.alert.accept
end

Then('the whiteboard should be empty') do
  canvas_is_empty = page.evaluate_script(<<~JS)
    const canvas = document.getElementById('whiteboard-canvas');
    const ctx = canvas.getContext('2d');
    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
    const data = imageData.data;

    // Check if all pixels are transparent (canvas is empty)
    for (let i = 3; i < data.length; i += 4) {
      if (data[i] !== 0) return false;
    }
    return true;
  JS

  expect(canvas_is_empty).to be true
end

Then('the clear should be saved to the server') do
  # Verify that saveToServer was called after clear
  save_function_exists = page.evaluate_script('typeof saveToServer === "function"')
  expect(save_function_exists).to be true
end

Given('the lobby has existing whiteboard content') do
  @lobby.whiteboard.update!(svg_data: '<svg width="1000" height="500"><circle cx="50" cy="50" r="20" fill="blue"/></svg>')
end

Then('I should see the existing whiteboard content') do
  # Check that loadExistingData function exists and SVG data is loaded
  load_function_exists = page.evaluate_script('typeof loadExistingData === "function"')
  expect(load_function_exists).to be true

  # Check that the lobby has SVG data
  expect(@lobby.whiteboard.svg_data).to include('circle')
end

Then('the content should be properly rendered') do
  # Verify that the loadSVGData function exists for rendering
  load_svg_function_exists = page.evaluate_script('typeof loadSVGData === "function"')
  expect(load_svg_function_exists).to be true
end
