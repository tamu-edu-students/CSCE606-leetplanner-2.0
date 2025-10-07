require 'rails_helper'

RSpec.describe "lobbies/show", type: :view do
  before(:each) do
    assign(:lobby, Lobby.create!(
      owner: nil,
      description: "MyText",
      members: "MyText",
      lobby_code: "Lobby Code"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/Lobby Code/)
  end
end
