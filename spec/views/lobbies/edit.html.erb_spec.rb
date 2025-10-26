require 'rails_helper'

RSpec.describe "lobbies/edit", type: :view do
  let(:lobby) {
    Lobby.create!(
      owner: nil,
      description: "MyText",
      lobby_code: "MyString"
    )
  }

  before(:each) do
    assign(:lobby, lobby)
  end

  it "renders the edit lobby form" do
    render

    assert_select "form[action=?][method=?]", lobby_path(lobby), "post" do
      assert_select "input[name=?]", "lobby[owner_id]"

      assert_select "textarea[name=?]", "lobby[description]"

      assert_select "input[name=?]", "lobby[lobby_code]"
    end
  end
end
