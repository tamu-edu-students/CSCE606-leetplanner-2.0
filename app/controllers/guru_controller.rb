class RetryableApiError < StandardError; end

class GuruController < ApplicationController
  before_action :require_login

  API_KEY = ENV["GEMINI_API_KEY"]
  API_URL = URI("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent?key=#{API_KEY}")

  SYSTEM_PROMPT = <<~PROMPT
    You are a helpful and expert coding assistant for an app called 'Leet Planner', nicknamed 'Guru'.
    Your goal is to help users understand LeetCode problems, debug code, explain complex
    data structures and algorithms, and provide time complexity analysis.
    Be concise, accurate, and encouraging. I want you to be sarcastic but helpful.
  PROMPT

  def index
    initial_messages = session[:guru_chat_messages] || []

    safe_messages = []
    initial_messages.each do |message|
      next unless message.is_a?(Hash)
      m = message.with_indifferent_access
      if m.present? && m[:text].present?
        safe_messages << m
      end
    end

    session[:guru_chat_messages] = safe_messages

    if session[:guru_chat_messages].empty?
      add_message_to_session("Hello! I'm Guru, your AI assistant. How can I help you today?", "bot")
    end

    @chat_messages = session[:guru_chat_messages]
  end

  def create_message
    user_message_text = params[:message]&.strip

    if user_message_text.blank?
      flash[:error] = "Message cannot be empty"
      redirect_to guru_path and return
    end

    add_message_to_session(user_message_text, "user")

    success, response_text = generate_response(user_message_text)
    bot_message = success ? response_text.to_s : "⚠️ Sorry, I couldn’t generate a response. Please try again."
    add_message_to_session(bot_message, "bot")

    redirect_to guru_path(anchor: "chat-bottom")
  end

  def clear_chat
    session[:guru_chat_messages] = []
    flash[:notice] = "Chat history cleared"
    redirect_to guru_path
  end

  private

  def require_login
    redirect_to root_path unless user_signed_in?
  end

  def add_message_to_session(message_text, sender)
    return if message_text.blank?

    messages = (session[:guru_chat_messages] || []).map(&:with_indifferent_access)

    messages << {
      text: message_text.strip,
      sender: sender,
      timestamp: Time.current.in_time_zone("Central Time (US & Canada)").strftime("%H:%M")
    }.with_indifferent_access

    messages = messages.last(50)

    session[:guru_chat_messages] = messages
  end

  def generate_response(message)
    if API_KEY.blank?
      return [false, "Error: The server is missing its API key."]
    end

    payload = {
      contents: [{ parts: [{ text: message }] }],
      systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] }
    }.to_json

    begin
      response = fetch_with_backoff(API_URL, payload)

      if response.is_a?(Net::HTTPSuccess)
        result = JSON.parse(response.body) rescue nil
        ai_response = result&.dig('candidates', 0, 'content', 'parts', 0, 'text')

        if ai_response.present?
          return [true, ai_response]
        else
          return [false, "Sorry — I couldn't parse a valid reply from the AI."]
        end
      else
        return [false, "Sorry, I ran into an API error (#{response&.code})."]
      end
    rescue => e
      Rails.logger.error "Guru: Server Error in generate_response: #{e.class} #{e.message}"
      return [false, "Sorry — an internal server error occurred while contacting the AI."]
    end
  end

  def fetch_with_backoff(uri, payload, max_retries = 4)
    retries = 0
    delay = 1

    begin
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.open_timeout = 5
      http.read_timeout = 15

      request = Net::HTTP::Post.new(uri.request_uri)
      request['Content-Type'] = 'application/json'
      request.body = payload

      response = http.request(request)

      case response.code
      when '200'
        return response
      when '429', '500', '503', '504'
        raise RetryableApiError, "API returned retryable code: #{response.code}"
      else
        return response
      end
    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, RetryableApiError => e
      if retries < max_retries
        sleep(delay)
        retries += 1
        delay *= 2
        retry
      else
        fake = Net::HTTPInternalServerError.new('1.1', '500', 'Internal Server Error')
        def fake.body; "Request failed after retries"; end
        return fake
      end
    rescue => e
      Rails.logger.error "Guru: Unexpected error in fetch_with_backoff: #{e.class} #{e.message}"
      raise
    end
  end
end
