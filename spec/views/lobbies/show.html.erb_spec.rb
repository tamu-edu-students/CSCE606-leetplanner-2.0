require 'rails_helper'

RSpec.describe "lobbies/show", type: :view do
  let(:owner) { create(:user) }
  let(:lobby) { create(:lobby, owner: owner, description: "MyText", lobby_code: "CODEX") }
  let!(:whiteboard) { lobby.whiteboard }

  before(:each) do
    assign(:lobby, lobby)
    def view.current_user
      @current_user_override || @owner
    end
    @owner = owner
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to include("MyText")
    expect(rendered).to include("CODEX")
  end

  describe "whiteboard UI layout" do
    before { render }

    it "displays the three-column layout with correct CSS classes" do
      expect(rendered).to have_css('.lobby-layout')
      expect(rendered).to have_css('.lobby-section', count: 3)
    end

    it "displays the shared notes section with correct structure" do
      expect(rendered).to have_css('.lobby-section:first-child')
      expect(rendered).to have_content('Shared Notes')
      expect(rendered).to have_css('.notes-area')
      expect(rendered).to have_css('.shared-notes, textarea')
    end

    it "displays the whiteboard section with enhanced styling" do
      whiteboard_section = Nokogiri::HTML(rendered).css('.lobby-section')[1]
      expect(whiteboard_section['class']).to include('whiteboard-section')
      expect(rendered).to have_content('Whiteboard')
      expect(rendered).to have_css('.whiteboard-container')
    end

    it "displays the participants section" do
      expect(rendered).to have_css('.lobby-section:last-child')
      expect(rendered).to have_content('Participants')
      expect(rendered).to have_css('.participants-list')
    end

    it "includes the enhanced whiteboard canvas with larger dimensions" do
      expect(rendered).to have_css('#whiteboard-canvas[width="1000"][height="500"]')
    end

    it "includes the whiteboard toolbar with all drawing tools" do
      expect(rendered).to have_css('.whiteboard-toolbar')
      expect(rendered).to have_css('#pencil-tool')
      expect(rendered).to have_css('#eraser-tool')
      expect(rendered).to have_css('#clear-btn')
      expect(rendered).to have_css('#color-picker')
      expect(rendered).to have_css('#brush-size')
    end

    it "includes JavaScript for whiteboard functionality" do
      expect(rendered).to include('whiteboard-canvas')
      expect(rendered).to include('getMousePos')
      expect(rendered).to include('canvasToSVG')
    end

    it "sets correct SVG dimensions in JavaScript" do
      expect(rendered).to include('width="1000" height="500"')
      expect(rendered).to include('viewBox="0 0 1000 500"')
    end

    it "includes responsive canvas sizing logic" do
      expect(rendered).to include('containerWidth < 1000')
      expect(rendered).to include("canvas.style.width = '1000px'")
      expect(rendered).to include("canvas.style.height = '500px'")
    end
  end

  describe "whiteboard permissions" do
    context "when user is the lobby owner" do
      it "allows drawing and note editing" do
        render
        expect(rendered).to include('canDraw = true')
        expect(rendered).to have_css('textarea.shared-notes')
        expect(rendered).to have_button('Save Notes')
      end
    end

    context "when user is a member with permissions" do
      let(:member) { create(:user) }
      let!(:lobby_member) { create(:lobby_member, lobby: lobby, user: member, can_draw: true, can_edit_notes: true) }

      before do
        @current_user_override = member
      end

      it "allows drawing and note editing based on permissions" do
        render
        expect(rendered).to include('canDraw = true')
      end
    end

    context "when user is a member without permissions" do
      let(:member) { create(:user) }
      let!(:lobby_member) { create(:lobby_member, lobby: lobby, user: member, can_draw: false, can_edit_notes: false) }

      before do
        @current_user_override = member
      end

      it "restricts drawing and note editing" do
        render
        expect(rendered).to include('canDraw = false')
        expect(rendered).to have_content("You don't have permission to edit notes")
        expect(rendered).to have_css('textarea[readonly]')
      end
    end
  end

  describe "responsive layout" do
    it "includes CSS for responsive grid layout" do
      render
      # Check that the CSS classes are present for responsive behavior
      expect(rendered).to have_css('.lobby-layout')
      expect(rendered).to have_css('.whiteboard-container')
    end

    it "includes mobile touch event handling" do
      render
      expect(rendered).to include('touchstart')
      expect(rendered).to include('touchmove')
      expect(rendered).to include('touchend')
    end
  end

  describe "whiteboard initialization" do
    context "when whiteboard exists" do
      it "loads existing whiteboard data" do
        render
        expect(rendered).to include('loadExistingData')
        expect(rendered).to include("fetch(`/lobbies/${lobbyId}/whiteboards.json`)")
      end
    end

    context "when whiteboard doesn't exist" do
      before do
        lobby.whiteboard.destroy
        lobby.reload
      end

      it "displays message about uninitialized whiteboard" do
        render
        expect(rendered).to have_content('Whiteboard not initialized')
      end
    end
  end
end
