# frozen_string_literal: true

class Scraper < Hamster::Scraper
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def prepare_body_for_next_page(eventvalidation, viewstate, viewstategenerator, target, page_num, total_pages, searchText)
    "__EVENTTARGET=#{CGI.escape target}&__EVENTARGUMENT=&__VIEWSTATE=#{CGI.escape  viewstate}&__VIEWSTATEGENERATOR=#{CGI.escape viewstategenerator}&__EVENTVALIDATION=#{CGI.escape eventvalidation}&txtSearch=Enter+Search+Term&SearchTerm=rdb2_CaseNumber&CurrentPages=#{page_num}&TotalPages=#{total_pages}&TotalRecords=&searchText=#{searchText}&searchType=Number&MobileDevice=False&btn#{page_num}=#{page_num}"
  end

  def prepare_pdf_body(eventvalidation, viewstate, viewstategenerator, pdf_link, url)
    number = url.split("=")[-2].scan(/\d/).join('')
    "__EVENTTARGET=#{CGI.escape pdf_link}&__EVENTARGUMENT=&__VIEWSTATE=#{CGI.escape viewstate}&__VIEWSTATEGENERATOR=#{CGI.escape viewstategenerator}&__EVENTVALIDATION=#{CGI.escape eventvalidation}&txtSearch=Enter+Search+Term&SearchTerm=rdb3_CaseNumber&hdPDF=&hdOpen=&hdMastId=#{number}"
  end

  def request_next_page(url)
    connect_to(url)
  end

  def fetch_outer_page(url)
    connect_to(url, headers:headers, proxy_filter: @proxy_filter)
  end
 
  def next_page_request(url, eventvalidation, viewstate, viewstategenerator, target, page_num, total_pages, searchText)
    body      = prepare_body_for_next_page(eventvalidation, viewstate, viewstategenerator, target, page_num, total_pages, searchText)
    updated_headers = headers.merge({
     "Origin" => "https://pch.tncourts.gov",
    })
    connect_to(url,  headers:updated_headers, req_body:body, method: :post, proxy_filter: @proxy_filter)
  end

  def pdf_request(eventvalidation, viewstate, viewstategenerator, pdf_link, url)
    body = prepare_pdf_body(eventvalidation, viewstate, viewstategenerator, pdf_link, url)
    updated_headers = headers.merge({
      "Origin" => "https://pch.tncourts.gov",
    })
    Hamster.connect_to(url,  headers:updated_headers, req_body:body, method: :post, proxy_filter: @proxy_filter)
  end

  private

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304,302].include?(response.status)
    end
    response
  end

  def headers
    {
      "Referer" => "https://pch.tncourts.gov/",
    }
  end
end
