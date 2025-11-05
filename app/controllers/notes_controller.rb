class NotesController < ApplicationController
  before_action :set_lobby
  before_action :authorize_edit!, only: [ :edit, :update ]

  def show
    @note = @lobby.note || @lobby.build_note(user: current_user)
  end

  def edit
    @note = @lobby.note || @lobby.build_note(user: current_user)
  end

  def create
    @note = @lobby.build_note(note_params.merge(user: current_user))

    if @note.save
      redirect_to @lobby, notice: "Note created successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update
    @note = @lobby.note || @lobby.build_note(user: current_user)

    if @note.persisted?
      # Update existing note
      if @note.update(note_params)
        redirect_to @lobby, notice: "Note updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    else
      # Create new note
      @note.assign_attributes(note_params)
      if @note.save
        redirect_to @lobby, notice: "Note updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  private

  def set_lobby
    @lobby = Lobby.find(params[:lobby_id])
  end

  def note_params
    params.require(:note).permit(:content)
  end

  def authorize_edit!
    member = @lobby.lobby_members.find_by(user: current_user)
    unless member&.can_edit_notes? || current_user == @lobby.owner
      redirect_to @lobby, alert: "You are not authorized to edit this note"
    end
  end
end
