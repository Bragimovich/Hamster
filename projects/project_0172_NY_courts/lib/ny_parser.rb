# frozen_string_literal: true


def parse_list_case_url(html)
  doc = Nokogiri::HTML(html)
  docket_ids = {}

  doc.xpath("//table/tbody/tr/td/a").map do |a|
    docket_id = a['href'].split('?docketId=')[-1].split('&')[0]
    next if docket_id.nil?
    case_id = a.content.strip
    docket_ids[case_id] = docket_id
  end
  docket_ids
end


def check_cases(html)
  doc = Nokogiri::HTML(html)
  doc.css('.searchResultsMessage')[0]
end

def check_cases_url(html)
  doc = Nokogiri::HTML(html)
  doc.css('.NewSearchResults')[0]
end


def captcha_page_html(html)
  doc = Nokogiri::HTML(html)
  doc.css('#captcha_form')[0]
end


def parse_last_page(html)
  doc = Nokogiri::HTML(html)
  url = doc.css('.pageNumbers').css('a')[-1]
  url['href'].split('PageNum=')[-1].to_i
end

def general_page_found(html)
  doc = Nokogiri::HTML(html)
  doc.css('div.DocumentBlock')[0]
end