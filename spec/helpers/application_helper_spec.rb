require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe "#format_event_time" do
    context "when the time value is blank" do
      it "returns an empty string if the value is nil" do
        expect(helper.format_event_time(nil)).to eq("")
      end

      it "returns an empty string if the value is an empty string" do
        expect(helper.format_event_time("")).to eq("")
      end
    end

    context "when the time value is a Time object" do
      it "formats a Time object correctly" do
        time = Time.zone.parse("2025-11-04 14:30:00")
        expect(helper.format_event_time(time)).to eq("2:30 PM")
      end

      it "strips leading spaces for single-digit hours" do
        time = Time.zone.parse("2025-11-04 09:05:00") # %l creates " 9:05 AM"
        expect(helper.format_event_time(time)).to eq("9:05 AM")
      end
    end

    context "when the time value is a String" do
      it "parses and formats a time string correctly" do
        time_string = "2025-11-04 18:45:00"
        expect(helper.format_event_time(time_string)).to eq("6:45 PM")
      end
    end
  end
end
