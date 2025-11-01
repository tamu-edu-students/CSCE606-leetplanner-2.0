require 'rails_helper'

RSpec.describe "whiteboard CSS styling", type: :request do
  let(:user) { create(:user) }
  let(:lobby) { create(:lobby, owner: user) }

  before do
    # Simulate login
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "GET /lobbies/:id" do
    it "includes optimized grid layout CSS classes" do
      get lobby_path(lobby)
      expect(response).to have_http_status(:success)

      # Check for the presence of key CSS classes that should be in the response
      expect(response.body).to include('lobby-layout')
      expect(response.body).to include('lobby-section')
      expect(response.body).to include('whiteboard-section')
      expect(response.body).to include('whiteboard-container')
    end

    it "includes enhanced canvas dimensions" do
      get lobby_path(lobby)
      expect(response).to have_http_status(:success)

      # Check for the new larger canvas dimensions
      expect(response.body).to include('width="1000"')
      expect(response.body).to include('height="500"')
    end

    it "includes updated SVG dimensions in JavaScript" do
      get lobby_path(lobby)
      expect(response).to have_http_status(:success)

      # Check for the updated SVG dimensions
      expect(response.body).to include('width="1000" height="500"')
      expect(response.body).to include('viewBox="0 0 1000 500"')
    end

    it "includes responsive canvas sizing logic" do
      get lobby_path(lobby)
      expect(response).to have_http_status(:success)

      # Check for the updated responsive logic
      expect(response.body).to include('containerWidth < 1000')
      expect(response.body).to include("canvas.style.width = '1000px'")
      expect(response.body).to include("canvas.style.height = '500px'")
    end

    it "includes all necessary whiteboard toolbar elements" do
      get lobby_path(lobby)
      expect(response).to have_http_status(:success)

      # Check for toolbar elements
      expect(response.body).to include('id="pencil-tool"')
      expect(response.body).to include('id="eraser-tool"')
      expect(response.body).to include('id="clear-btn"')
      expect(response.body).to include('id="color-picker"')
      expect(response.body).to include('id="brush-size"')
    end

    it "includes whiteboard functionality JavaScript functions" do
      get lobby_path(lobby)
      expect(response).to have_http_status(:success)

      # Check for key JavaScript functions
      expect(response.body).to include('function getMousePos')
      expect(response.body).to include('function canvasToSVG')
      expect(response.body).to include('function loadSVGData')
      expect(response.body).to include('function saveToServer')
    end
  end
end
