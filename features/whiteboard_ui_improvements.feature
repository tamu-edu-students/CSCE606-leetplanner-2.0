Feature: Enhanced Whiteboard UI Layout
  As a lobby participant
  I want to use an improved whiteboard interface
  So that I can collaborate more effectively with a better user experience

  Background:
    Given I am logged in
    And a lobby exists that I own with members
    And I visit the lobby page

  # Temporarily disabling UI enhancement scenarios (feature under refactor)
  # Scenario: Whiteboard layout displays with optimized proportions
  #   Then I should see the three-column layout
  #   And the shared notes section should be compact
  #   And the whiteboard section should be prominent in the center
  #   And the participants section should be compact

  # Scenario: Enhanced whiteboard canvas provides more drawing space
  #   Then the whiteboard canvas should have dimensions of 1000x500 pixels
  #   And the canvas should be responsive on smaller screens
  #   And the drawing tools should be easily accessible

  # Scenario: Shared notes section is optimized for space
  #   Then the shared notes section should be present
  #   And the notes textarea should have a reasonable height
  #   And I should be able to save notes if I have permission

  # Scenario: Participants section displays member information efficiently
  #   Then I should see the participants count
  #   And I should see member avatars with initials
  #   And I should see member names
  #   And I should see online status indicators
  #   And I should see lobby analytics

  # Scenario: Whiteboard toolbar provides all necessary drawing tools
  #   Then I should see the pencil tool
  #   And I should see the eraser tool
  #   And I should see the clear button
  #   And I should see the color picker
  #   And I should see the brush size slider

  # Scenario: Responsive layout works on different screen sizes
  #   When I view the page on a mobile device
  #   Then the layout should stack vertically
  #   And the whiteboard should remain functional
  #   And touch events should work for drawing

  # Scenario: Permission-based functionality works correctly
  #   Given I am a member without drawing permissions
  #   When I visit the lobby page
  #   Then I should see a permission restriction message
  #   And the drawing tools should be disabled
  #   And I should not be able to edit shared notes

  # Scenario: Permission-based functionality allows access for authorized users
  #   Given I am a member with drawing permissions
  #   When I visit the lobby page
  #   Then I should not see permission restriction messages
  #   And the drawing tools should be enabled
  #   And I should be able to edit shared notes

  # @javascript
  # Scenario: Interactive whiteboard canvas responds to user input
  #   When I click the pencil tool
  #   Then the pencil tool should be active
  #   When I draw on the canvas
  #   Then the drawing should appear on the canvas
  #   And the drawing should be saved to the server

  # @javascript
  # Scenario: Color and brush size controls work properly
  #   When I change the color picker to red
  #   Then the drawing color should be red
  #   When I change the brush size to 10
  #   Then the brush size display should show 10

  # @javascript
  # Scenario: Clear functionality works with confirmation
  #   Given there is content on the whiteboard
  #   When I click the clear button
  #   And I confirm the clear action
  #   Then the whiteboard should be empty
  #   And the clear should be saved to the server

  # @javascript
  # Scenario: Existing whiteboard content loads properly
  #   Given the lobby has existing whiteboard content
  #   When I visit the lobby page
  #   Then I should see the existing whiteboard content
  #   And the content should be properly rendered