# frozen_string_literal: true

class PdfParser
  def initialize(pdf_url)
    @reader = PDF::Reader.new(open(pdf_url))
  end

  def get_table_data
    table_data = []
    from_title, to_title = get_page_title()
    start_page = @reader.pages.count
    while start_page > 0 do
      start_page -= 1
      break if @reader.page(start_page).text.match(/(Students by Associated School District or Charter School)/)
    end

    (start_page..@reader.pages.count).to_a.each do |page_num|
      page = @reader.page(page_num)
      break if to_title && page.text.include?(to_title)
      
      match1 = page.text.match(/(District\/Charter)/)
      match2 = page.text.match(/^(\d+)?\s+(\D+)\s{3}(\d+|\*)?$/)
      if match1 || match2 && match2[1]
        table_data.concat get_page_info(page)
      end
    end
    table_data
  end

  private

  def get_page_title
    from_title = nil
    to_title   = nil
    @reader.pages.each_with_index do |page, page_num|
      break if page.text.nil? || page_num > 5

      next unless page.text.include?('Table of Contents')

      text_array = page.text.split("\n").reject(&:empty?)
      text_array.each_with_index do |text_line, ind|
        if text_line.match(/^[Appendix].*(Students by Associated School)/i)
          from_title = nil
          to_title   = nil
          match = text_line.match(/\d\s+(\w.*[^\.])\.+\s?(\d+)/)
          from_title = match[1]
          if text_array[ind + 1]&.strip && !text_array[ind + 1].strip.empty?
            match = text_array[ind+1].match(/\d\s+(\w.*[^\.])\.+\s?(\d+)/i)
            to_title = match[1] if match
          end
        elsif text_line.match(/(Students by Associated School District or Charter School)/i)
          from_title = nil
          to_title   = nil
          match = text_line.match(/\d\s+(\w.*[^\.])\.+\s?(\d+)/i)
          from_title = match[1]
          if text_array[ind + 1]&.strip && !text_array[ind + 1].strip.empty?
            match = text_array[ind+1].match(/\d\s+(\w.*[^\.])\.+\s?(\d+)/i)
            to_title = match[1] if match
          end
        end
      end
    end
    [from_title&.strip, to_title&.strip]
  end

  def get_page_info(page)
    receiver = Hamster::TableReceiver.new
    page.walk(receiver)

    receiver.columns
  end
end
