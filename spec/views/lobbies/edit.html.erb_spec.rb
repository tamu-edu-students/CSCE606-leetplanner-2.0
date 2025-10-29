require 'rails_helper'

RSpec.describe "lobbies/edit", type: :view do
  let(:owner) { create(:user) }
  let(:lobby) { create(:lobby, owner: owner, description: "MyText", lobby_code: "MYCODE") }

  before(:each) do
    assign(:lobby, lobby)
  end

  it "renders the edit lobby form" do
    render

    assert_select "form[action=?][method=?]", lobby_path(lobby), "post" do
      assert_select "textarea[name=?]", "lobby[description]"
    end
  end
end
