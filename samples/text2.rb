#!/usr/bin/env ruby

$LOAD_PATH.unshift "../packages/cairo/ext/"
$LOAD_PATH.unshift "../packages/cairo/lib/"

require 'optparse'
require 'ostruct'

require 'cairo'
require 'pango'

def parse(args=ARGV)
  options = OpenStruct.new
  options.width = 595.275590551181.round
  options.height = 841.889763779528.round
  options.font_description = "Monospace 12"
  options.fade_out = false

  opts = OptionParser.new do |opts|
    opts.on("--width=WIDTH", Integer, "paper width") {|options.width|}
    opts.on("--height=HEIGHT", Integer, "paper height") {|options.height|}
    opts.on("--font-description=DESCRIPTION",
            "font description (e.g. 'Monospace 14')") do |desc|
      options.font_description = desc
    end
    opts.on("--[no-]fade-out",
            "fade-out one-third of page") {|options.fade_out|}
  end

  opts.parse!(args)

  options
end

def render_background(cr)
  cr.set_source_rgba(1.0, 1.0, 1.0)
  cr.paint
end

def make_layout(cr, text, width, font_description)
  layout = cr.create_pango_layout
  layout.text = text
  layout.width = width * Pango::SCALE
  layout.font_description = Pango::FontDescription.new(font_description)
  cr.update_pango_layout(layout)
  layout
end

def setup_fade_out(cr, width)
  fade_out = Cairo::LinearPattern.new(0, 0, width, 0)
  fade_out.add_color_stop_rgba(0, 0, 0, 0, 1)
  fade_out.add_color_stop_rgba(0.66, 0, 0, 0, 1)
  fade_out.add_color_stop_rgba(1, 0, 0, 0, 0)

  cr.set_source(fade_out)
end

def render_layout(cr, layout, initial_x, initial_y, initial_rest_height)
  x = initial_x
  y = initial_y
  rest_height = initial_rest_height

  layout.lines.each do |line|
    ink_rect, logical_rect = line.pixel_extents
    line_height = logical_rect.height
    if rest_height < line_height
      cr.show_page
      y = initial_y
      rest_height = initial_rest_height
    end
    cr.move_to(x + logical_rect.x, y - logical_rect.y)
    cr.show_pango_layout_line(line)
    y += line_height
    rest_height -= line_height
  end
end

def render(options, output, surface_class)
  text = options.text
  width = options.width
  height = options.height
  font_description = options.font_description
  fade_out = options.fade_out

  margin_left = (width * 0.05).ceil
  margin_right = (width * 0.05).ceil
  margin_top = (height * 0.05).ceil
  margin_bottom = (height * 0.05).ceil
  body_width = width - margin_left - margin_right
  body_height = height - margin_top - margin_bottom

  surface = surface_class.new(output, width, height)
  cr = Cairo::Context.new(surface)

  render_background(cr)
  layout = make_layout(cr, text, body_width, font_description)
  if fade_out
    setup_fade_out(cr, body_width)
  else
    cr.set_source_rgba(0, 0, 0, 1)
  end
  render_layout(cr, layout, margin_left, margin_top, body_height)

  cr.show_page

  cr.target.finish
  cr
end

def output(options, surface_class_name, suffix)
  if Cairo.const_defined?(surface_class_name)
    surface_class = Cairo.const_get(surface_class_name)
    render(options, "text2.#{suffix}", surface_class)
  else
    puts("#{surface_class_name} isn't supported.")
  end
end

options = parse
options.text = ARGF.read
output(options, "PSSurface", "ps")
output(options, "PDFSurface", "pdf")
output(options, "SVGSurface", "svg")