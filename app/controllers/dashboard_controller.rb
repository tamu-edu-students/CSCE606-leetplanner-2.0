# Controller for the main dashboard functionality
# Handles Google Calendar integration, event tracking, and timer management
class DashboardController < ApplicationController
  # Required Google APIs and time handling libraries
  require "google/apis/calendar_v3"
  require "time"
  require "date"

  # GET /dashboard
  # Display the main dashboard with current events and timer information
  def show
    # Initialize instance variables for dashboard display
    @current_event = nil              # Currently active Google Calendar event
    @event_ends_at = nil             # End time of current event
    @event_ends_at_formatted = nil   # Formatted end time for display
    @time_remaining_seconds = nil    # Remaining time in seconds
    @time_remaining_hms = nil        # Remaining time in HH:MM:SS format

    # If no Google session token, render basic dashboard without calendar integration
    return unless session[:google_token]

    begin
      # Set up Google Calendar service with OAuth2 authentication
      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = Signet::OAuth2::Client.new(
        access_token: session[:google_token],
        refresh_token: session[:google_refresh_token],
        client_id: ENV["GOOGLE_CLIENT_ID"],
        client_secret: ENV["GOOGLE_CLIENT_SECRET"],
        token_credential_uri: ENV["GOOGLE_OAUTH_URI"]
      )

      # Fetch a short window of events including current/ongoing ones
      # Look for events within 7 days before and after current time
      now = Time.now.utc

      response = service.list_events(
        "primary",                                    # Use primary calendar
        max_results: 20,                             # Limit to 20 events
        single_events: true,                         # Expand recurring events
        order_by: "startTime",                       # Order by start time
        time_min: (now - 7.days).iso8601,          # 7 days ago
        time_max: (now + 7.days).iso8601           # 7 days from now
      )

      # Find an event that contains the current time (ongoing event)
      event = response.items.find do |e|
        # Parse start time (handle both datetime and date-only events)
        start_time = e.start&.date_time&.to_time&.utc ||
                     (e.start&.date && Time.parse(e.start.date).utc)

        # Parse end time (handle both datetime and date-only events)
        end_time = e.end&.date_time&.to_time&.utc ||
                   (e.end&.date && (Time.parse(e.end.date).utc - 1)) # Inclusive for all-day events

        # Check if current time falls within event duration
        start_time && end_time && now.between?(start_time, end_time)
      end

      # If we found a current event, set up timing information
      if event
        @current_event = event

        # Determine event end time based on event type
        if event.end&.date_time
          # Timed event - use exact datetime
          @event_ends_at = event.end.date_time.to_time.utc
        elsif event.end&.date
          # All-day event - use end of day
          @event_ends_at = (Time.zone.parse(event.end.date) - 1) # Inclusive for all-day events
        end

        # Calculate and format remaining time if event has an end time
        if @event_ends_at
          @event_ends_at_formatted = @event_ends_at.strftime("%d-%b-%Y %H:%M:%S")
          rem = (@event_ends_at - Time.now.utc).to_i
          rem = 0 if rem.negative?  # Don't show negative time

          # Convert seconds to hours, minutes, seconds
          h = rem / 3600
          m = (rem % 3600) / 60
          s = rem % 60

          @time_remaining_seconds = rem
          @time_remaining_hms = format("%02d:%02d:%02d", h, m, s)
        end
      elsif session[:timer_ends_at]
        # If no current calendar event, check for manual timer
        @timer_ends_at = Time.zone.parse(session[:timer_ends_at])

        if @timer_ends_at <= Time.now.utc
          # Timer has expired, clean up session
          session.delete(:timer_ends_at)
          @timer_ends_at = nil
        else
          # Timer is still active, calculate remaining time
          remaining_seconds = (@timer_ends_at - Time.current).to_i
          hours = remaining_seconds / 3600
          minutes = (remaining_seconds % 3600) / 60
          seconds = remaining_seconds % 60
          @time_remaining_hms = format("%02d:%02d:%02d", hours, minutes, seconds)
        end
      end
    rescue Google::Apis::ServerError, Google::Apis::ClientError, Google::Apis::AuthorizationError => e
      flash.now[:error] = "Unable to sync with Google Calendar"
      Rails.logger.error("Google Calendar sync failed: #{e.class} #{e.message}")
    rescue StandardError => e
      # Log any other errors but don't break the dashboard
      Rails.logger.error("Dashboard#show error: #{e.class} #{e.message}")
    end
  end

  # POST /dashboard/create_timer
  # Create a manual timer for the specified number of minutes
  def create_timer
    minutes = params[:minutes].to_i
    if minutes > 0
      # Store timer end time in session
      session[:timer_ends_at] = (Time.now.utc + minutes.minutes).iso8601
    end
    # Redirect back to dashboard to show the new timer
    redirect_to dashboard_path
  end
end
