class LobbyChannel < ApplicationCable::Channel
  def subscribed
    stream_for Lobby.find(params[:lobby_id])
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def speak(data)
    LobbyChannel.broadcast_to(Lobby.find(params[:lobby_id]), message: data["message"])
  end
end
