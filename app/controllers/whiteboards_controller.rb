class WhiteboardsController < ApplicationController
  before_action :set_lobby
  before_action :set_whiteboard

  def add_drawing
    svg_data = @whiteboard.svg_data || create_default_svg
    
    case params[:tool]
    when 'rectangle'
      svg_data = add_rectangle_to_svg(svg_data, params[:x], params[:y], params[:width], params[:height], params[:color] || '#ffffff')
    when 'circle'
      svg_data = add_circle_to_svg(svg_data, params[:x], params[:y], params[:radius], params[:color] || '#ffffff')
    when 'text'
      svg_data = add_text_to_svg(svg_data, params[:x], params[:y], params[:text], params[:color] || '#ffffff')
    end
    
    @whiteboard.update(svg_data: svg_data)
    redirect_to lobby_path(@lobby), notice: "Added #{params[:tool]} to whiteboard!"
  end

  def clear
    @whiteboard.update(svg_data: create_default_svg)
    redirect_to lobby_path(@lobby), notice: "Whiteboard cleared!"
  end

  private

  def set_lobby
    @lobby = Lobby.find(params[:lobby_id])
  end

  def set_whiteboard
    @whiteboard = @lobby.whiteboard || @lobby.create_whiteboard(name: "#{@lobby.name} Whiteboard")
  end

  def create_default_svg
    <<~SVG
      <svg width="100%" height="350" viewBox="0 0 800 350" xmlns="http://www.w3.org/2000/svg" class="whiteboard-svg">
        <defs>
          <pattern id="grid" width="20" height="20" patternUnits="userSpaceOnUse">
            <path d="M 20 0 L 0 0 0 20" fill="none" stroke="#333" stroke-width="0.5" opacity="0.3"/>
          </pattern>
        </defs>
        <rect width="100%" height="100%" fill="url(#grid)"/>
      </svg>
    SVG
  end

  def add_rectangle_to_svg(svg_data, x, y, width, height, color)
    doc = Nokogiri::XML(svg_data)
    svg = doc.at('svg')
    
    rect = doc.create_element('rect',
      x: x,
      y: y,
      width: width,
      height: height,
      fill: 'none',
      stroke: color,
      'stroke-width': '3',
      'stroke-opacity': '0.9'
    )
    
    svg.add_child(rect)
    doc.to_xml
  end

  def add_circle_to_svg(svg_data, x, y, radius, color)
    doc = Nokogiri::XML(svg_data)
    svg = doc.at('svg')
    
    circle = doc.create_element('circle',
      cx: x,
      cy: y,
      r: radius,
      fill: 'none',
      stroke: color,
      'stroke-width': '3',
      'stroke-opacity': '0.9'
    )
    
    svg.add_child(circle)
    doc.to_xml
  end

  def add_text_to_svg(svg_data, x, y, text, color)
    doc = Nokogiri::XML(svg_data)
    svg = doc.at('svg')
    
    text_element = doc.create_element('text',
      x: x,
      y: y,
      fill: color,
      'font-family': 'Arial, sans-serif',
      'font-size': '18',
      'font-weight': 'bold',
      'text-anchor': 'start'
    )
    text_element.content = text.to_s
    
    svg.add_child(text_element)
    doc.to_xml
  end
end