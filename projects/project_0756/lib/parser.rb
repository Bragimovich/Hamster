# frozen_string_literal: true

class Parser < Hamster::Parser

  def page(page)
    @doc = Nokogiri::HTML(page)
    self
  end

  def excel_links
    links = @doc.at_css("#2009-2022_data").css("a[href$='.xlsx']").map do |link|
      link[:href]
    end
    links.compact
  end

end
