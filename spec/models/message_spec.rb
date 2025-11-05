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
end
