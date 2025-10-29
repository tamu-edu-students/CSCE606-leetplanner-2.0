require 'rails_helper'

RSpec.describe "lobbies/index", type: :view do
  before(:each) do
    owner = create(:user)
    assign(:lobbies, [ create(:lobby, owner: owner, description: "MyText", lobby_code: "CODE1"), create(:lobby, owner: owner, description: "MyText", lobby_code: "CODE2") ])
  end

  it "renders a list of lobbies" do
    render
    expect(rendered).to include("MyText")
  end
end
