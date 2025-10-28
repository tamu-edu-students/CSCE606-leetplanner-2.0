class LobbiesController < ApplicationController
  before_action :set_lobby, only: %i[ show edit update destroy ]

  # GET /lobbies or /lobbies.json
  def index
    joined_lobbies = current_user.lobbies
    public_unjoined_lobbies = Lobby.where(private: false).where.not(id: joined_lobbies.pluck(:id))
    @lobbies =  joined_lobbies + public_unjoined_lobbies
  end

  # GET /lobbies/1 or /lobbies/1.json
  def show
    @lobby = Lobby.includes(lobby_members: :user).find(params[:id])
  end

  # GET /lobbies/new
  def new
    @lobby = Lobby.new
  end

  # GET /lobbies/1/edit
  def edit
  end

  # POST /lobbies or /lobbies.json
  def create
    @lobby = Lobby.new(lobby_params)
    LobbyMember.create(user: current_user, lobby: @lobby)

    respond_to do |format|
      if @lobby.save
        format.html { redirect_to @lobby, notice: "Lobby was successfully created." }
        format.json { render :show, status: :created, location: @lobby }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @lobby.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /lobbies/1 or /lobbies/1.json
  def update
    respond_to do |format|
      if @lobby.update(lobby_params)
        format.html { redirect_to @lobby, notice: "Lobby was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @lobby }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @lobby.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /lobbies/1 or /lobbies/1.json
  def destroy
    if current_user.id == @lobby.owner_id
      @lobby.lobby_members.each {
        |member|
        member.destroy!
      }
      @lobby.destroy!
      respond_to do |format|
        format.html { redirect_to lobbies_path, notice: "Lobby was successfully destroyed.", status: :see_other }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to lobbies_path, alert: "You are not authorized to destroy this lobby.", status: :forbidden }
        format.json { render json: { error: "Unauthorized" }, status: :forbidden }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_lobby
      @lobby = Lobby.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def lobby_params
      params.expect(lobby: [ :owner_id, :description, :lobby_code, :name, :private ])
    end
end
