require 'rails_helper'

RSpec.describe LobbyChannel, type: :channel do

  let!(:owner) { User.create!(
    netid: "testuser123",
    email: "test@example.com",
    first_name: "Test",
    last_name: "User"
  ) }

  let!(:lobby) { Lobby.create!(
    name: "Test Lobby",
    owner: owner
  ) }

  before do
    # Stub the connection
    stub_connection
  end

  describe "#subscribed" do
    it "successfully subscribes and streams for the correct lobby" do
      # Pass the channel params to the subscribe method
      # This provides the `params[:lobby_id]`
      subscribe(lobby_id: lobby.id)

      # Test that the subscription was successful
      expect(subscription).to be_confirmed
      
      expect(subscription).to have_stream_for(lobby)
    end
  end

  describe "#speak" do
    before do
      # A client must be subscribed to be able to speak
      # This subscribe call also needs the params
      subscribe(lobby_id: lobby.id)
    end

    it "broadcasts the message to the correct lobby stream" do
      expect {
        perform(:speak, message: "Hello!")
      }.to have_broadcasted_to(lobby).with(message: "Hello!")
    end
  end
end
