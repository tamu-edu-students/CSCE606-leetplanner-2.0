class LobbyMember < ApplicationRecord
  belongs_to :user
  belongs_to :lobby
end
