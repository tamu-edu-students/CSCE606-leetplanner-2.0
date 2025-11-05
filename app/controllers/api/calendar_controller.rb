# Required Google APIs for calendar integration
require "google/apis/calendar_v3"
require "googleauth"

# API module for calendar-related endpoints
module Api
  # API controller for Google Calendar operations
  # Handles CRUD operations for calendar events with Google Calendar integration
  class CalendarController < ApplicationController
    # Ensure event has a name before creating or updating
    before_action :ensure_event_name_present, only: [ :create, :update ]

    # GET /api/calendar/events
    # Fetch calendar events from Google Calendar for a specified date range
    def events
      # Check for Google authentication
      unless session[:google_token]
        redirect_to login_google_path, alert: "Not authenticated with Google."
        return
      end

      # Get authenticated calendar service or return early if unauthorized
      service = calendar_service_or_unauthorized or return

      # Set up parameters for event fetching
      calendar_id = "primary"
      start_time = params[:start_date] || Time.now.beginning_of_month.iso8601  # Default to current month start
      end_time   = params[:end_date] || Time.now.end_of_month.iso8601         # Default to current month end

      begin
        # Fetch events from Google Calendar API
        response = service.list_events(
          calendar_id,
          single_events: true,      # Expand recurring events into individual instances
          order_by: "startTime",    # Sort by start time
          time_min: start_time,     # Earliest event time
          time_max: end_time,       # Latest event time
          max_results: 50           # Limit number of results
        )

        # Transform Google Calendar events into standardized format
        events = response.items.map do |event|
          {
            id: event.id,
            summary: event.summary,
            start: event.start&.date_time || event.start&.date,    # Handle both timed and all-day events
            end: event.end&.date_time || event.end&.date,          # Handle both timed and all-day events
            location: event.location,
            description: event.description
          }
        end

        # Redirect with success message (this endpoint redirects rather than returning JSON)
        redirect_to calendar_path(anchor: "calendar"), notice: "Events loaded."
      rescue Google::Apis::AuthorizationError => e
        # Handle authorization errors
        Rails.logger.error("Calendar authorization error: #{e.message}")
        redirect_to dashboard_path(anchor: "calendar"), alert: "Failed to load events due to authorization."
      rescue => e
        # Handle any other errors
        Rails.logger.error("Calendar error: #{e.message}")
        redirect_to calendar_path(anchor: "calendar"), alert: "Failed to load events."
      end
    end

    # POST /api/calendar/events
    # Create a new calendar event in Google Calendar and corresponding LeetCode session
    def create
      # Get authenticated calendar service or return early if unauthorized
      service = calendar_service_or_unauthorized or return

      # Parse all_day flag from parameters
      all_day = ActiveModel::Type::Boolean.new.cast(params.dig(:event, :all_day))

      # Set timezone for consistent time handling
      Time.zone = "America/Chicago"

      # Set default values for date/time if not provided
      current_time = Time.current
      current_date = current_time.to_date.to_s  # Always get current date
      start_date = params.dig(:event, :start_date)

      begin
        Date.parse(start_date) if start_date.present?
      rescue Date::Error
        return render json: { error: "Invalid date format" }, status: :unprocessable_entity
      end

      start_time = params.dig(:event, :start_time).presence || current_time.strftime("%H:%M")
      start_time_param = params.dig(:event, :start_time).presence || current_time.strftime("%H:%M")

      # Create event datetime objects based on all_day flag
      if all_day
        # All-day event: use date only, spans entire day
        start_et = Google::Apis::CalendarV3::EventDateTime.new(
          date: start_date,
          time_zone: "America/Chicago"
        )
        end_et = Google::Apis::CalendarV3::EventDateTime.new(
          date: Date.parse(start_date).next_day.to_s,  # All-day events end the next day
          time_zone: "America/Chicago"
        )
      else
        # Timed event: use specific datetime
        start_datetime = Time.zone.parse("#{start_date} #{start_time}").iso8601
        start_et = Google::Apis::CalendarV3::EventDateTime.new(
          date_time: start_datetime,
          time_zone: "America/Chicago"
        )

        # Set end time (use provided end_time or default to 30 minutes later)
        end_time = params.dig(:event, :end_time)
        end_datetime = if end_time.present?
                        Time.zone.parse("#{start_date} #{end_time}").iso8601
        else
                        (Time.zone.parse(start_datetime) + 30.minutes).iso8601
        end
        end_et = Google::Apis::CalendarV3::EventDateTime.new(
          date_time: end_datetime,
          time_zone: "America/Chicago"
        )
      end

      # Create Google Calendar event object
      ev = Google::Apis::CalendarV3::Event.new(
        summary:     params.dig(:event, :summary),
        description: params.dig(:event, :description),
        location:    params.dig(:event, :location),
        start:       start_et,
        end:         end_et
      )

      begin
        # Create event in Google Calendar
        created = service.insert_event("primary", ev)
        flash[:notice] = "Event successfully created."

        # === CREATE CORRESPONDING LEETCODE SESSION ===
        # Calculate start and end times for LeetCode session
        start_time = if all_day
                      Date.parse(start_date).beginning_of_day.in_time_zone("America/Chicago")
        else
                      Time.zone.parse("#{start_date} #{start_time_param}")
        end

        end_time = if all_day
                    Date.parse(start_date).end_of_day.in_time_zone("America/Chicago")
        else
                    Time.zone.parse(end_et.date_time || (start_time + 30.minutes).iso8601)
        end

        # Calculate duration in minutes (minimum 1 minute)
        duration_minutes = [ (end_time - start_time) / 60, 1 ].max.to_i

        # Create LeetCode session linked to the calendar event
        LeetCodeSession.create!(
          user_id: current_user.id,
          google_event_id: created.id,
          title: params.dig(:event, :summary).presence || "Untitled Session",
          description: params.dig(:event, :description),
          scheduled_time: start_time,
          duration_minutes: duration_minutes,
          status: if end_time < Time.current
                    "completed"  # Mark as completed if end time is in the past
                  else
                    "scheduled"  # Mark as scheduled if end time is in the future
                  end
        )
        # === END LEETCODE SESSION CREATION ===

        # Respond with success
        respond_to do |format|
          format.html { redirect_to calendar_path, notice: "Event successfully created." }
          format.json { render json: serialize_event(created), status: :created }
        end
      rescue Google::Apis::ClientError, Google::Apis::ServerError => e
        # Handle Google API errors
        error_message = e.respond_to?(:message) ? e.message : "Failed to create event"
        Rails.logger.error("Calendar create: #{error_message}")
        respond_to do |format|
          format.html { redirect_to calendar_path, alert: error_message }
          format.json { render json: { error: error_message }, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /api/calendar/events/:id
    # Update an existing calendar event in Google Calendar
    def update
      # Get authenticated calendar service or return early if unauthorized
      service = calendar_service_or_unauthorized or return

      # Extract and validate event parameters
      event_params = params.require(:event).permit(:summary, :start_date, :start_time, :end_time, :location, :description, :all_day)

      # Parse all_day flag
      all_day = ActiveModel::Type::Boolean.new.cast(event_params[:all_day])

      # Get existing event from Google Calendar
      event = service.get_event("primary", params[:id])

      # Create patch object with only the fields that are being updated
      patch = Google::Apis::CalendarV3::Event.new

      # Update basic fields if they are present in parameters
      patch.summary = event_params[:summary] if event_params[:summary].present?
      patch.description = event_params[:description] if event_params[:description].present?
      patch.location = event_params[:location] if event_params[:location].present?

      # Handle start and end times based on all_day flag
      if event_params[:start_time].present? || event_params[:start_date].present?
        Time.zone = "America/Chicago"

        if all_day
          # All-day event: use date only
          start_date = event_params[:start_date].presence || event_params[:start_time]
          patch.start = Google::Apis::CalendarV3::EventDateTime.new(
            date: Date.parse(start_date).to_s
          )
          patch.end = Google::Apis::CalendarV3::EventDateTime.new(
            date: Date.parse(start_date).next_day.to_s  # All-day events end the next day
          )
        else
          # Timed event: parse datetime from date and time components
          datetime = if event_params[:start_date].present? && event_params[:start_time].present?
                Time.zone.parse("#{event_params[:start_date]} #{event_params[:start_time]}")
          elsif event_params[:start_time].present?
                Time.zone.parse(event_params[:start_time])
          else
                Time.zone.parse(event_params[:start_date])
          end

          # Set start time
          patch.start = Google::Apis::CalendarV3::EventDateTime.new(
            date_time: datetime.iso8601,
            time_zone: "America/Chicago"
          )

          # Set end time (use provided end_time or default to 30 minutes later)
          if event_params[:end_time].present?
            end_datetime = Time.zone.parse("#{event_params[:start_date] || datetime.to_date} #{event_params[:end_time]}")
            patch.end = Google::Apis::CalendarV3::EventDateTime.new(
              date_time: end_datetime.iso8601,
              time_zone: "America/Chicago"
            )
          else
            patch.end = Google::Apis::CalendarV3::EventDateTime.new(
              date_time: (datetime + 30.minutes).iso8601,
              time_zone: "America/Chicago"
            )
          end
        end
      end

      # Update the event in Google Calendar
      updated = service.update_event("primary", params[:id], patch)

      # Respond with success
      respond_to do |format|
        format.html { redirect_to calendar_path, notice: "Event successfully updated." }
        format.json { render json: serialize_event(updated) }
      end
    rescue Google::Apis::ClientError => e
      # Handle Google API errors
      Rails.logger.error("Calendar update error: #{e.message}")
      respond_to do |format|
        format.html { redirect_to calendar_path, alert: "Failed to update event." }
        format.json { render json: { error: "Failed to update event" }, status: :unprocessable_entity }
      end
    end

    # DELETE /api/calendar/events/:id
    # Delete a calendar event from Google Calendar
    def destroy
      # Get authenticated calendar service or return early if unauthorized
      service = calendar_service_or_unauthorized or return

      # Delete the event from Google Calendar
      service.delete_event("primary", params[:id])

      # Respond with success
      respond_to do |format|
        format.html { redirect_to calendar_path(anchor: "calendar"), notice: "Event deleted." }
      end
      rescue Google::Apis::ClientError => e
        # Handle Google API errors
        Rails.logger.error("Calendar delete: #{e.message}")
        respond_to do |format|
          format.html { redirect_to calendar_path(anchor: "calendar"), alert: "Failed to delete event." }
        end
    end

    private

    # Validation method to ensure event has a name/summary
    def ensure_event_name_present
      # Check for event name in both nested and flat parameter formats
      name = params.dig(:event, :summary).presence || params[:summary].presence
      return if name.to_s.strip.present?

      # Return error if no name provided
      msg = "Event name is required."
      respond_to do |format|
        format.html { redirect_back fallback_location: calendar_path, alert: msg }
        format.json { render json: { error: msg }, status: :unprocessable_entity }
      end
    end

    # Build authorized Google Calendar service or handle authentication errors
    # Returns nil and redirects if user is not properly authenticated
    def calendar_service_or_unauthorized
      # Check if user has Google token in session
      unless session[:google_token].present?
        redirect_to login_google_path, alert: "Please log in with Google to continue."
        return nil
      end

      # Create OAuth2 client with session tokens
      client = Signet::OAuth2::Client.new(
        access_token:         session[:google_token],
        refresh_token:        session[:google_refresh_token],
        client_id:            ENV["GOOGLE_CLIENT_ID"],
        client_secret:        ENV["GOOGLE_CLIENT_SECRET"],
        token_credential_uri: ENV["GOOGLE_OAUTH_URI"]
      )

      # Refresh token if expired or near expiry (within 5 minutes)
      begin
        if session[:google_token_expires_at].present?
          expiry_time = Time.at(session[:google_token_expires_at].to_i)
          if expiry_time - Time.now < 300 # 5 minutes buffer
            client.refresh!
            session[:google_token] = client.access_token
            session[:google_token_expires_at] = client.expires_at.to_i
            Rails.logger.info("Token refreshed, new expiry: #{Time.at(session[:google_token_expires_at].to_i)}")
          end
        else
          # No expiry time stored, refresh to be safe
          client.refresh!
          session[:google_token] = client.access_token
          session[:google_token_expires_at] = client.expires_at.to_i
        end
      rescue Signet::AuthorizationError => e
        # Handle token refresh failure
        Rails.logger.error("Token refresh failed: #{e.message}")
        reset_session
        redirect_to login_google_path, alert: "Your session expired. Please log in again."
        return nil
      end

      # Update session with current tokens
      session[:google_token] = client.access_token
      session[:google_refresh_token] ||= client.refresh_token

      # Create and configure Google Calendar service
      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = client
      service
    end

    # Helper method to build EventDateTime objects for all-day or timed events
    # Handles both date-only and datetime formats
    def event_time(raw, all_day)
      return nil if raw.blank?

      # Check if this is a date-only format or all-day event
      if all_day || raw.to_s.match?(/\A\d{4}-\d{2}-\d{2}\z/)
        d = Date.parse(raw) rescue nil
        return Google::Apis::CalendarV3::EventDateTime.new(date: d&.iso8601)
      end

      # Parse as datetime for timed events
      t = Time.zone.parse(raw) rescue nil
      Google::Apis::CalendarV3::EventDateTime.new(
        date_time: t&.iso8601,
        time_zone: Time.zone.name
      )
    end

    # Serialize Google Calendar event into standardized hash format
    def serialize_event(event)
      {
        id:          event.id,
        summary:     event.summary,
        start:       event.start&.date_time || event.start&.date,    # Handle both timed and all-day events
        end:         event.end&.date_time   || event.end&.date,      # Handle both timed and all-day events
        location:    event.location,
        description: event.description
      }
    end
  end
end
