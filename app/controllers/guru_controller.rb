# frozen_string_literal: true

# Controller for handling the Guru chat interface
# Provides ChatGPT-like functionality for users to ask questions
class GuruController < ApplicationController
  before_action :require_login
  before_action :initialize_chat_session

  # Display the main chat interface
  def index
    @chat_messages = session[:guru_chat_messages] || []
    # Clean up any empty messages
    @chat_messages = @chat_messages.reject { |msg| msg[:text].blank? }
    session[:guru_chat_messages] = @chat_messages
  end

  # Handle new chat messages
  def create_message
    user_message = params[:message]&.strip

    if user_message.blank?
      flash[:error] = "Message cannot be empty"
      redirect_to guru_path
      return
    end

    # Add user message to chat history
    add_message_to_session(user_message, "user")

    # Generate bot response
    bot_response = generate_response(user_message)
    add_message_to_session(bot_response, "bot")

    # Redirect back to index to show updated chat
    redirect_to guru_path
  end

  # Clear chat history
  def clear_chat
    session[:guru_chat_messages] = []
    flash[:notice] = "Chat history cleared"
    redirect_to guru_path
  end

  private

  def require_login
    redirect_to root_path unless user_signed_in?
  end

  def initialize_chat_session
    session[:guru_chat_messages] ||= []

    # Add welcome message if this is a new session
    if session[:guru_chat_messages].empty?
      add_message_to_session("Hello! I'm Guru, your AI assistant. How can I help you today?", "bot")
    end
  end

  def add_message_to_session(message, sender)
    return if message.blank? # Don't add empty messages

    session[:guru_chat_messages] ||= []
    session[:guru_chat_messages] << {
      text: message.strip,
      sender: sender,
      timestamp: Time.current.strftime("%H:%M")
    }

    # Keep only last 50 messages to prevent session from getting too large
    session[:guru_chat_messages] = session[:guru_chat_messages].last(50)
  end

  # Placeholder method for generating responses
  # In a real implementation, this would call an LLM API
  def generate_response(message)
    case message.downcase
    when /hello|hi|hey/
      "Hello! I'm Guru, your AI assistant. How can I help you today?"
    when /help/
      "I can help you with various questions and tasks. Feel free to ask me anything!"
    when /leetcode|coding|algorithm/
      "I can help you with coding problems and algorithm questions. What specific topic would you like to discuss?"
    when /calendar|schedule/
      "I can assist with calendar and scheduling related questions. What would you like to know?"
    when /clear|reset/
      "I understand you want to start fresh. You can use the 'Clear Chat' button to reset our conversation."
    else
      "That's an interesting question! I'm here to help. Could you provide more context or ask me something specific?"
    end
  end
end
