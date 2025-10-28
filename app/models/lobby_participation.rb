class LobbyParticipation < ApplicationRecord
  belongs_to :user
  belongs_to :lobby
end
