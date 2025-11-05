class WhiteboardsController < ApplicationController
  # Consolidated controller (removed duplicate definitions). Keep implementation minimal for specs.
  before_action :set_lobby
  before_action :set_whiteboard

  # JSON whiteboard state
  def show
    render json: { svg_data: @whiteboard.svg_data, notes: @whiteboard.notes }
  end

  # Add simple shape/text primitives by string injection (sufficient for tests)
  def add_drawing
    tool  = params[:tool]
    color = params[:color].presence || "#000000"
    case tool
    when "rectangle"
      @whiteboard.svg_data = add_rectangle_to_svg(@whiteboard.svg_data, params[:x], params[:y], params[:width], params[:height], color)
      flash[:notice] = "Added rectangle to whiteboard!"
    when "circle"
      @whiteboard.svg_data = add_circle_to_svg(@whiteboard.svg_data, params[:x], params[:y], params[:radius], color)
      flash[:notice] = "Added circle to whiteboard!"
    when "text"
      @whiteboard.svg_data = add_text_to_svg(@whiteboard.svg_data, params[:x], params[:y], params[:text], color)
      flash[:notice] = "Added text to whiteboard!"
    when "line"
      width = params[:width].presence || "2"
      @whiteboard.svg_data = add_line_to_svg(@whiteboard.svg_data, params[:x1], params[:y1], params[:x2], params[:y2], color, width)
      flash[:notice] = "Added line to whiteboard!"
    else
      flash[:alert] = "Unknown tool"
    end
    @whiteboard.save(validate: false)
    redirect_to lobby_path(@lobby)
  end

  def clear
    @whiteboard.update(svg_data: create_default_svg, notes: @whiteboard.notes)
    flash[:notice] = "Whiteboard cleared!"
    redirect_to lobby_path(@lobby)
  end

  def update_svg
    return render json: { status: "error", message: "No SVG data provided" }, status: :bad_request unless params[:svg_data].present?
    if @whiteboard.update(svg_data: params[:svg_data])
      render json: { status: "success" }
    else
      render json: { status: "error", message: "Failed to persist SVG" }, status: :unprocessable_entity
    end
  end

  def update_notes
    unless permitted_to_edit_notes? && params.dig(:whiteboard, :notes).present?
      flash[:alert] = "Not authorized to edit notes."
      return redirect_to lobby_path(@lobby)
    end
    if @whiteboard.update(notes: params[:whiteboard][:notes])
      flash[:notice] = "Notes updated."
    else
      flash[:alert] = "Failed to update notes."
    end
    redirect_to lobby_path(@lobby)
  end

  private

  def set_lobby
    @lobby = Lobby.find(params[:lobby_id])
  end

  def set_whiteboard
    existing = @lobby.whiteboard
    if existing
      @whiteboard = existing
    else
      @whiteboard = @lobby.build_whiteboard(svg_data: create_default_svg)
      # Persist without triggering validations that may not be relevant to initial placeholder.
      @whiteboard.save(validate: false)
    end
  end

  def permitted_to_edit_notes?
    return false unless current_user
    return true if current_user == @lobby.owner
    member = @lobby.lobby_members.find_by(user: current_user)
    member&.can_edit_notes == true
  end

  def create_default_svg
    <<~SVG.strip
      <svg width="800" height="350" viewBox="0 0 800 350" xmlns="http://www.w3.org/2000/svg" class="whiteboard-svg">
        <defs>
          <pattern id="grid" width="25" height="25" patternUnits="userSpaceOnUse">
            <path d="M 25 0 L 0 0 0 25" fill="none" stroke="#ccc" stroke-width="1" />
          </pattern>
        </defs>
        <rect width="100%" height="100%" fill="url(#grid)" />
      </svg>
    SVG
  end

  def ensure_svg_wrapper(svg)
    return create_default_svg unless svg.present? && svg.include?("</svg>")
    svg
  end

  def inject_before_close(svg, fragment)
    svg = ensure_svg_wrapper(svg)
    svg.sub(/<\/svg>\s*\z/, "  #{fragment}\n</svg>")
  end

  def add_rectangle_to_svg(svg, x, y, width, height, color)
    frag = %(<rect x="#{x}" y="#{y}" width="#{width}" height="#{height}" fill="none" stroke="#{color}" stroke-width="2" />)
    inject_before_close(svg, frag)
  end

  def add_circle_to_svg(svg, cx, cy, r, color)
    frag = %(<circle cx="#{cx}" cy="#{cy}" r="#{r}" fill="none" stroke="#{color}" stroke-width="2" />)
    inject_before_close(svg, frag)
  end

  def add_text_to_svg(svg, x, y, text, color)
    safe_text = ERB::Util.h(text)
    frag = %(<text x="#{x}" y="#{y}" fill="#{color}" font-size="16" font-family="Arial, sans-serif">#{safe_text}</text>)
    inject_before_close(svg, frag)
  end

  def add_line_to_svg(svg, x1, y1, x2, y2, color, width)
    frag = %(<line x1="#{x1}" y1="#{y1}" x2="#{x2}" y2="#{y2}" stroke="#{color}" stroke-width="#{width}" />)
    inject_before_close(svg, frag)
  end
end
