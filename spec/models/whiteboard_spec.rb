require 'rails_helper'

RSpec.describe Whiteboard, type: :model do
  let(:whiteboard) { build(:whiteboard) }

  describe 'associations' do
    it 'belongs to lobby' do
      expect(whiteboard.lobby).to be_a(Lobby)
    end
  end

  describe 'validations' do
    it 'is valid with default factory' do
      expect(whiteboard).to be_valid
    end

    it 'requires name' do
      whiteboard.name = ''
      expect(whiteboard).not_to be_valid
      expect(whiteboard.errors[:name]).to be_present
    end

    it 'limits svg_data length' do
      whiteboard.svg_data = '<svg>' + 'x' * 250_001 + '</svg>'
      expect(whiteboard).not_to be_valid
      expect(whiteboard.errors[:svg_data]).to be_present
    end

    it 'limits notes length' do
      whiteboard.notes = 'n' * 25_001
      expect(whiteboard).not_to be_valid
      expect(whiteboard.errors[:notes]).to be_present
    end
  end

  describe '#append_svg_element!' do
    it 'appends element when svg_data present' do
      whiteboard.svg_data = '<svg xmlns="http://www.w3.org/2000/svg"></svg>'
      whiteboard.save!
      expect {
        whiteboard.append_svg_element!('<rect x="0" y="0" width="10" height="10" />')
      }.to change { whiteboard.reload.svg_data.include?('<rect') }.from(false).to(true)
    end

    it 'does nothing when element_xml blank' do
      whiteboard.svg_data = '<svg xmlns="http://www.w3.org/2000/svg"></svg>'
      whiteboard.save!
      expect {
        whiteboard.append_svg_element!(nil)
      }.not_to change { whiteboard.reload.svg_data }
    end
  end
end

