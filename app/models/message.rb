class Message < ApplicationRecord
  belongs_to :user
  belongs_to :lobby

  # Validate presence of message body
  validates :body, presence: true

  after_commit :broadcast_message, on: :create

  def broadcast_message
    broadcast_append_to lobby if lobby.present?
  end
end
