class Lobby < ApplicationRecord
  belongs_to :owner, class_name: "User"

  validates :lobby_code, presence: true, uniqueness: true
  validates :owner, presence: true
  validates :name, presence: true

  has_many :lobby_members
  has_many :users, through: :lobby_members
  has_one :whiteboard, dependent: :destroy

  has_one :note, dependent: :destroy
  accepts_nested_attributes_for :note

  accepts_nested_attributes_for :lobby_members
  before_validation :generate_lobby_code, on: :create
  after_create :create_default_whiteboard

  private

  def generate_lobby_code
    chars = ("A".."Z").to_a - %w[O I]
    digits = ("2".."9").to_a
    self.lobby_code ||= loop do
      code = (chars + digits).sample(6).join
      break code unless Lobby.exists?(lobby_code: code)
    end
  end

  def create_default_whiteboard
    self.create_whiteboard(name: "#{self.name} Whiteboard", description: "Shared whiteboard for #{self.name}")
  end
end
