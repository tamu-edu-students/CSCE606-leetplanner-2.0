import consumer from "./consumer"

export function subscribeToWhiteboard(lobbyId, onUpdate) {
  return consumer.subscriptions.create({ channel: "WhiteboardChannel", lobby_id: lobbyId }, {
    received(data) {
      if (data.svg_data) {
        onUpdate(data.svg_data)
      }
    }
  })
}
