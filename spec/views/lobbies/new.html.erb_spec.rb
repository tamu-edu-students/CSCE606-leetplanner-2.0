require 'rails_helper'

RSpec.describe "lobbies/new", type: :view do
  before(:each) do
    assign(:lobby, Lobby.new(description: "MyText"))
    def view.current_user
      @owner ||= FactoryBot.create(:user)
    end
  end

  it "renders new lobby form" do
    render

    assert_select "form[action=?][method=?]", lobbies_path, "post" do
      assert_select "textarea[name=?]", "lobby[description]"
    end
  end
end
