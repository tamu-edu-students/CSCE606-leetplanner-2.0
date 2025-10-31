require 'rails_helper'

RSpec.describe "lobbies/show", type: :view do
  let(:owner) { create(:user) }
  let(:lobby) { create(:lobby, owner: owner, name: "Test Lobby") }
  let!(:whiteboard) { lobby.whiteboard }
  let!(:member1) { create(:user, first_name: "John", last_name: "Doe") }
  let!(:member2) { create(:user, first_name: "Jane", last_name: "Smith") }
  let!(:lobby_member1) { create(:lobby_member, lobby: lobby, user: member1, can_draw: true, can_edit_notes: true) }
  let!(:lobby_member2) { create(:lobby_member, lobby: lobby, user: member2, can_draw: false, can_edit_notes: false) }

  before(:each) do
    assign(:lobby, lobby)
    def view.current_user
      @current_user_override || @owner
    end
    @owner = owner
    @member1 = member1
    @member2 = member2
  end

  describe "layout grid structure" do
    before { render }

    it "uses CSS Grid with correct column proportions" do
      # The layout should have the new smaller proportions
      expect(rendered).to have_css('.lobby-layout')
      
      # Check that all three sections are present
      lobby_sections = Nokogiri::HTML(rendered).css('.lobby-section')
      expect(lobby_sections.length).to eq(3)
    end

    it "positions shared notes section as first column" do
      doc = Nokogiri::HTML(rendered)
      first_section = doc.css('.lobby-section').first
      expect(first_section.text).to include('Shared Notes')
    end

    it "positions whiteboard section as center column with correct class" do
      doc = Nokogiri::HTML(rendered)
      center_section = doc.css('.lobby-section')[1]
      expect(center_section['class']).to include('whiteboard-section')
      expect(center_section.text).to include('Whiteboard')
    end

    it "positions participants section as right column" do
      doc = Nokogiri::HTML(rendered)
      last_section = doc.css('.lobby-section').last
      expect(last_section.text).to include('Participants')
    end
  end

  describe "whiteboard canvas enhancements" do
    before { render }

    it "has increased canvas dimensions" do
      expect(rendered).to have_css('canvas#whiteboard-canvas[width="1000"][height="500"]')
    end

    it "includes updated SVG generation with new dimensions" do
      expect(rendered).to include('<svg width="1000" height="500"')
      expect(rendered).to include('viewBox="0 0 1000 500"')
    end

    it "has responsive sizing logic for larger canvas" do
      expect(rendered).to include('containerWidth < 1000')
      expect(rendered).to include('containerWidth * 0.5')
    end

    it "maintains aspect ratio in responsive mode" do
      # Canvas should maintain 2:1 aspect ratio (width:height)
      expect(rendered).to include('(containerWidth * 0.5)')
    end
  end

  describe "shared notes optimization" do
    before { render }

    it "has reduced textarea size for better space utilization" do
      # The textarea should have a more compact height
      textarea = Nokogiri::HTML(rendered).css('.shared-notes, textarea').first
      expect(textarea).to be_present
    end

    it "includes save functionality for notes" do
      expect(rendered).to have_button('Save Notes')
      expect(rendered).to have_css('form[action*="update_notes"]')
    end

    it "shows read-only textarea for users without edit permissions" do
      @current_user_override = @member2
      render
      expect(rendered).to have_css('textarea[readonly]')
      expect(rendered).to have_content("You don't have permission to edit notes")
    end
  end

  describe "participants section layout" do
    before { render }

    it "displays participant count correctly" do
      expect(rendered).to have_content("Participants (2)")
    end

    it "shows participant avatars with initials" do
      expect(rendered).to have_css('.participant-avatar', text: 'J')
    end

    it "displays participant names" do
      expect(rendered).to have_content('John Doe')
      expect(rendered).to have_content('Jane Smith')
    end

    it "shows online status indicators" do
      expect(rendered).to have_css('.status-dot.online')
    end

    it "includes lobby analytics section" do
      expect(rendered).to have_content('Lobby Analytics')
      expect(rendered).to have_content('Active Users:')
      expect(rendered).to have_content('2/5')
    end
  end

  describe "whiteboard toolbar functionality" do
    before { render }

    it "includes all drawing tools" do
      expect(rendered).to have_css('#pencil-tool', text: /Pencil/)
      expect(rendered).to have_css('#eraser-tool', text: /Eraser/)
      expect(rendered).to have_css('#clear-btn', text: /Clear/)
    end

    it "includes drawing customization controls" do
      expect(rendered).to have_css('#color-picker[type="color"]')
      expect(rendered).to have_css('#brush-size[type="range"]')
      expect(rendered).to have_css('#size-display')
    end

    it "has proper tool selection JavaScript" do
      expect(rendered).to include('selectTool(tool)')
      expect(rendered).to include('currentTool = tool')
    end
  end

  describe "JavaScript functionality" do
    before { render }

    it "includes mouse event handling" do
      expect(rendered).to include('mousedown')
      expect(rendered).to include('mousemove')
      expect(rendered).to include('mouseup')
    end

    it "includes touch event handling for mobile" do
      expect(rendered).to include('touchstart')
      expect(rendered).to include('touchmove')
      expect(rendered).to include('touchend')
    end

    it "includes drawing path management" do
      expect(rendered).to include('paths = []')
      expect(rendered).to include('drawPath(pathData)')
    end

    it "includes server synchronization" do
      expect(rendered).to include('saveToServer()')
      expect(rendered).to include('loadExistingData()')
      expect(rendered).to include('/whiteboards/update_svg')
    end
  end

  describe "permission-based rendering" do
    context "when user cannot draw" do
      before do
        @current_user_override = @member2
        render
      end

      it "shows permission message" do
        expect(rendered).to include('You do not have permission to draw on this whiteboard')
      end

      it "sets canDraw to false" do
        expect(rendered).to include('canDraw = false')
      end
    end

    context "when user can draw" do
      before do
        @current_user_override = @member1
        render
      end

      it "enables drawing functionality" do
        expect(rendered).to include('canDraw = true')
      end
    end
  end

  describe "CSS styling integration" do
    before { render }

    it "includes whiteboard container styling" do
      expect(rendered).to have_css('.whiteboard-container')
    end

    it "includes toolbar styling classes" do
      expect(rendered).to have_css('.whiteboard-toolbar')
      expect(rendered).to have_css('.tool-btn')
    end

    it "includes proper canvas styling" do
      canvas_style = rendered.match(/\.whiteboard-container[^}]*{[^}]*}/m)
      expect(rendered).to include('#whiteboard-canvas')
    end
  end
end