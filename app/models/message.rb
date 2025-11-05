class Message < ApplicationRecord
  belongs_to :user
  belongs_to :lobby

  # Validate presence of message body
  validates :body, presence: true

  after_commit :broadcast_message, on: :create

  def broadcast_message
    if lobby.present?
      begin
        broadcast_append_to "lobby_#{lobby.id}_messages"
      rescue ArgumentError => e
        if e.message.include?("No unique index found for")
          Rails.logger.error "Turbo Stream Broadcast Failed for Message ##{self.id}: #{e.message}. The record was saved."
        else
          raise e
        end
      rescue => e
        Rails.logger.error "Unexpected error during broadcast for Message ##{self.id}: #{e.message}"
      end
    end
  end
end
