require 'rails_helper'

RSpec.describe "lobbies/index", type: :view do
  before(:each) do
    assign(:lobbies, [
      Lobby.create!(
        owner: nil,
        description: "MyText",
        members: "MyText",
        lobby_code: "Lobby Code"
      ),
      Lobby.create!(
        owner: nil,
        description: "MyText",
        members: "MyText",
        lobby_code: "Lobby Code"
      )
    ])
  end

  it "renders a list of lobbies" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Lobby Code".to_s), count: 2
  end
end
