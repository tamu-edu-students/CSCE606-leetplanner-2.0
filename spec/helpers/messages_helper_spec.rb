require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the MessagesHelper. For example:
#
# describe MessagesHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe MessagesHelper, type: :helper do
  describe '#formatted_timestamp' do
    it 'formats time to HH:MM 24h' do
      time = Time.zone.parse('2025-01-02 14:35:10')
      expect(helper.formatted_timestamp(time)).to eq('14:35')
    end
  end

  describe '#safe_message_body' do
    it 'returns empty string for nil' do
      expect(helper.safe_message_body(nil)).to eq('')
    end

    it 'escapes HTML tags' do
      expect(helper.safe_message_body('<b>hi</b>')).to eq('&lt;b&gt;hi&lt;/b&gt;')
    end

    it 'strips surrounding whitespace' do
      expect(helper.safe_message_body("  hello  ")).to eq('hello')
    end
  end
end
