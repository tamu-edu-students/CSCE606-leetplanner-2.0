class Message < ApplicationRecord
  belongs_to :user
  belongs_to :lobby

  after_create_commit { broadcast_append_to lobby }
end
