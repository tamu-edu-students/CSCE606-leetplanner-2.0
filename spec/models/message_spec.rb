require 'rails_helper'

RSpec.describe Message, type: :model do
  it 'has a valid factory' do
    expect(build(:message)).to be_valid
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:lobby) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:body) }
  end

  describe 'callbacks' do
    it 'broadcasts after create (append to lobby stream)' do
      lobby = create(:lobby)
      user = lobby.owner
      msg = build(:message, lobby: lobby, user: user)
      # Spy on the singleton broadcast method via expectation on instance
      expect(msg).to receive(:broadcast_append_to).with(lobby)
      msg.save!
    end
  end
end
