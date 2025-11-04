require 'rails_helper'

RSpec.describe ApplicationCable::Connection, type: :channel do
  # This tests the default connection behavior
  it "successfully connects" do
    # Simulates a client connecting to the /cable endpoint
    connect "/cable"
    
    # Verifies that an instance of your connection class was created
    expect(connection).to be_a(ApplicationCable::Connection)
  end
end
