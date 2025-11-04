class Message < ApplicationRecord
  belongs_to :user
  belongs_to :lobby

  # Validate presence of message body
  validates :body, presence: true

  # Broadcast new messages to the lobby after create (ActionCable / Turbo Streams)
  after_create_commit { broadcast_append_to lobby }
end
