module MessagesHelper
  # Formats a message timestamp for display in chat.
  # Returns a string like "14:35" (24h) given a Time/DateTime.
  def formatted_timestamp(time)
    time.strftime("%H:%M")
  end

  # Simple sanitization helper for message bodies in case raw strings appear.
  # Leverages Rails escape once and strips extraneous whitespace.
  def safe_message_body(body)
    return "" if body.nil?
    CGI.escapeHTML(body.to_s).strip
  end
end
