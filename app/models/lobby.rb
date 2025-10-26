class Lobby < ApplicationRecord
  belongs_to :owner, class_name: "User"

  validates :lobby_code, presence: true, uniqueness: true
  # TODO: Remove members
  attribute :members, :json, default: []
  validates :owner, presence: true

  has_many :lobby_members
  has_many :users, through: :lobby_members

  before_validation :generate_lobby_code, on: :create

  def add_member(user)
    self.members ||= []
    self.members |= [ user.id ] # union to prevent duplicates
    save
  end

  def remove_member(user)
    self.members ||= []
    self.members.delete(user.id)
    save
  end

  def member?(user)
    self.members&.include?(user.id)
  end

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
