  class MessagesController < ApplicationController
  before_action :set_lobby
  before_action :authenticate_user! # if you have authentication

  def create
    @message = @lobby.messages.build(message_params)
    @message.user = current_user
    puts "--DEBUG MESSAGE--"
    puts @lobby.id
    puts @message.id

    if @message.save
      # Message creation succeeded; Turbo Streams will handle broadcasting
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @lobby, notice: "Message sent!" }
      end
    else
      # Handle error - could re-render or respond with errors
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("messages_form", partial: "messages/form", locals: { message: @message }) }
        format.html { redirect_to @lobby, alert: "Failed to send message." }
      end
    end
  end

  private

  def set_lobby
    @lobby = Lobby.find(params[:lobby_id])
  end

  def message_params
    params.require(:message).permit(:body)
  end
  end
