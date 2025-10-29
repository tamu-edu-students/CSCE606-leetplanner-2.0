class Note < ApplicationRecord
  belongs_to :lobby
  belongs_to :user

  validates :content, presence: true
  validates :lobby_id, uniqueness: true
end
