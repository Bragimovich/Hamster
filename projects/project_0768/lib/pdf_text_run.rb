# frozen_string_literal: true

class PDFTextRun < PDF::Reader::TextRun
  attr_accessor :row
  attr_reader   :clip_y, :order

  def initialize(x, y, width, font_size, text, clip_y, order)
    super(x, y, width, font_size, text)

    @clip_y = clip_y
    @order  = order
  end
end
