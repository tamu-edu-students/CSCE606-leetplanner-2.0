class Lobby < ApplicationRecord
  belongs_to :owner, class_name: "User"

  validates :lobby_code, presence: true, uniqueness: true
  validates :owner, presence: true

  has_many :lobby_members
  has_many :users, through: :lobby_members
  has_many :lobby_participations, dependent: :destroy

  before_validation :generate_lobby_code, on: :create

  private

  def generate_lobby_code
    chars = ("A".."Z").to_a - %w[O I]
    digits = ("2".."9").to_a
    self.lobby_code ||= loop do
      code = (chars + digits).sample(6).join
      break code unless Lobby.exists?(lobby_code: code)
    end
  end
end
