# User model representing system users (students and admins)
# Handles user authentication, profile information, and relationships with coding sessions
class User < ApplicationRecord
  # Validation rules for required fields
  validates :netid, presence: true, uniqueness: true  # NetID must be present and unique
  validates :email, presence: true, uniqueness: true  # Email must be present and unique
  validates :first_name, presence: true               # First name is required
  validates :last_name, presence: true                # Last name is required

  # Email format validations using URI regex
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }  # Validate primary email format
  validates :personal_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true  # Validate personal email format (optional)

  # Define valid user roles and validate role assignment
  VALID_ROLES = %w[student admin].freeze
  validates :role, inclusion: { in: VALID_ROLES }, allow_nil: true  # Role must be either 'student' or 'admin'

  # Associations with other models
  has_many :leet_code_sessions, dependent: :destroy  # User can have multiple coding sessions, destroy when user is deleted
  #TODO: Remove owned lobbies
  has_many :owned_lobbies, class_name: "Lobby", foreign_key: "owner_id"
  has_many :events                                   # User can have multiple calendar events
  has_many :lobby_members
  has_many :lobbies, through: :lobby_members

  # Scopes for common queries
  scope :active, -> { where(active: true) }      # Find only active users
  scope :with_email, -> { where.not(email: nil) } # Find users who have email addresses

  # Instance method to get user's full name
  def full_name
    "#{first_name} #{last_name}"  # Concatenate first and last name
  end  
  def joined_lobbies
    Lobby.where("members::jsonb ? :user_id", user_id: id.to_s)
  end
end
