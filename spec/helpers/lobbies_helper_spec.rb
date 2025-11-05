require 'rails_helper'

RSpec.describe LobbiesHelper, type: :helper do
  describe 'helper module' do
    it 'is included in helper methods' do
      expect(helper.class.included_modules).to include(LobbiesHelper)
    end
  end
end
