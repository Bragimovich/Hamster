# frozen_string_literal: true

class PageUrl < Hamster::Parser
  def initialize(url, page_number)
    @page = get_page_from_url(url, page_number).to_i
    @url = get_url_for_different_page(url, page_number)
  end

  def next_page_url
    @page += 1
    @url.gsub("{{NEXTPAGE}}", @page.to_s)
  end

  private

  def get_url_for_different_page(url, page_number)
    url.gsub("#{page_number}=#{@page}", "#{page_number}={{NEXTPAGE}}")
  end

  def get_page_from_url(url, page_number)
    url.split("#{page_number}=")[-1].split('&')[0]
  end
end
