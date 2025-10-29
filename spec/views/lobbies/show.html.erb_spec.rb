require 'rails_helper'

RSpec.describe "lobbies/show", type: :view do
  before(:each) do
    owner = create(:user)
    assign(:lobby, create(:lobby, owner: owner, description: "MyText", lobby_code: "CODEX"))
    allow(view).to receive(:current_user).and_return(owner)
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to include("MyText")
    expect(rendered).to include("CODEX")
  end
end
