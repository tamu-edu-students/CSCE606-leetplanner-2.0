# Application-wide helper methods
# Contains utility methods that can be used across all views in the application
module ApplicationHelper
  # Add application-wide helper methods here
  # These methods will be available in all view templates
  def format_event_time(time_value)
    # Return an empty string if the value is blank (nil or empty)
    return "" if time_value.blank?

    # Ensure the value is a Time object before formatting
    time_obj = time_value.is_a?(String) ? Time.zone.parse(time_value) : time_value
    time_obj&.strftime("%l:%M %p")&.strip
  end
end
