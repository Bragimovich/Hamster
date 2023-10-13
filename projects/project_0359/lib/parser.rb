# frozen_string_literal: true

class Parser < Hamster::Parser
  def get_file_link(response)
    page = Nokogiri::HTML response.body
    link = page.css('a.resource-url-analytics')[0]['href']
  end
end
