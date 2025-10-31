require 'rails_helper'

RSpec.describe "lobbies/index", type: :view do
  before(:each) do
    owner = create(:user)
    assign(:lobbies, [ create(:lobby, owner: owner, description: "MyText", lobby_code: "CODE1"), create(:lobby, owner: owner, description: "MyText", lobby_code: "CODE2") ])
    def view.current_user
      @owner ||= FactoryBot.create(:user)
    end
  end

  it "renders a list of lobbies" do
    render
    expect(rendered).to have_content("Collaborative Lobbies")
    expect(rendered).to have_css('.lobby-card')
  end
end
