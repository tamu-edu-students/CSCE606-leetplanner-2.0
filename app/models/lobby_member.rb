class LobbyMember < ApplicationRecord
  belongs_to :user
  belongs_to :lobby

  validates :user_id, uniqueness: { scope: :lobby_id, message: "is already in this lobby" }
end
