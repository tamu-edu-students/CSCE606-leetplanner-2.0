class WhiteboardChannel < ApplicationCable::Channel
  def subscribed
    lobby = Lobby.find(params[:lobby_id])
    stream_for lobby
  end

  def receive(data)
    lobby = Lobby.find(data['lobby_id'])
    whiteboard = lobby.whiteboard
    if data['svg_data'].present?
      whiteboard.update(svg_data: data['svg_data'])
      WhiteboardChannel.broadcast_to(lobby, { svg_data: whiteboard.svg_data })
    elsif data['cursor'].present?
      # Broadcast cursor position without persisting
      WhiteboardChannel.broadcast_to(lobby, { cursor: data['cursor'] })
    end
  end
end
