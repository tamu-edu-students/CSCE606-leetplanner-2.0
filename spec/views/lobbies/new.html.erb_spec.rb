require 'rails_helper'

RSpec.describe "lobbies/new", type: :view do
  before(:each) do
    assign(:lobby, Lobby.new(
      owner: nil,
      description: "MyText",
      lobby_code: "MyString"
    ))
  end

  it "renders new lobby form" do
    render

    assert_select "form[action=?][method=?]", lobbies_path, "post" do
      assert_select "input[name=?]", "lobby[owner_id]"

      assert_select "textarea[name=?]", "lobby[description]"

      assert_select "input[name=?]", "lobby[lobby_code]"
    end
  end
end
