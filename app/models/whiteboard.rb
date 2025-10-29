class Whiteboard < ApplicationRecord
  belongs_to :lobby
  validates :name, presence: true, allow_blank: false
  validates :svg_data, length: { maximum: 250_000 }, allow_nil: true
  # Notes can be blank but limit extremely large payloads (client-side we could enforce too)
  validates :notes, length: { maximum: 25_000 }, allow_nil: true

  # Helper to append raw SVG snippet safely inside existing root <svg>
  def append_svg_element!(element_xml)
    return if element_xml.blank?
    return if svg_data.blank?

    doc = Nokogiri::XML(svg_data)
    svg = doc.at('svg')
    fragment_doc = Nokogiri::XML(element_xml)
    new_node = fragment_doc.root
    svg.add_child(new_node)
    update(svg_data: doc.to_xml)
  end
end

