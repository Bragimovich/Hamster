# frozen_string_literal: true
require_relative '../lib/parser'

class Scraper < Hamster::Scraper
  MAIN_PAGE  = 'https://jccweb.jacksongov.org/inmatesearch/Default.aspx'
  INNER_PAGE = 'https://jccweb.jacksongov.org/inmatesearch/frmInmateDetails.aspx'
  IMAGE_URL  = 'https://jccweb.jacksongov.org/inmatesearch/frmGetInmateImage.aspx'

  def initialize
    super
  end

  def search_main_page
    connect_to(MAIN_PAGE)
  end

  def search_pagination(gen_values, cookie, page)
    connect_to(url: MAIN_PAGE, headers: get_headers(cookie), req_body: paginated_body(gen_values, page), method: :post)
  end

  def search_results_page(gen_values, cookie)
    connect_to(url: MAIN_PAGE, headers: get_headers(cookie), req_body: prepare_body(gen_values), method: :post)
  end

  def search_inner_page(gen_values, cookie, page)
    connect_to(url: MAIN_PAGE, headers: get_headers(cookie), req_body: prepare_inner_body(gen_values, page), method: :post)
    inner_response = connect_to(url: INNER_PAGE, headers: get_headers(cookie))
    img_response = connect_to(url: IMAGE_URL, headers: img_headers(cookie))
    [inner_response, img_response]
  end

  private

  def get_headers(cookie)
    {
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "Accept-Language" => "en-US,en;q=0.9",
      "Cache-Control" => "max-age=0",
      "Connection" => "keep-alive",
      "Cookie" => cookie,
      "Origin" => "https://jccweb.jacksongov.org",
      "Referer" => "https://jccweb.jacksongov.org/inmatesearch/Default.aspx"
      }
  end

  def img_headers(cookie)
    {
    "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
    "Accept-Language" => "en-US,en;q=0.9",
    "Cache-Control" => "max-age=0",
    "Connection" => "keep-alive",
    "Cookie" => cookie,
    "Sec-Fetch-Dest" => "document"
    }
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do 
      response = super(*arguments, &block)
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end
  
  def prepare_body(gen_values)
    "__VIEWSTATE=#{CGI.escape gen_values[0]}&__VIEWSTATEGENERATOR=#{CGI.escape gen_values[2]}&__EVENTVALIDATION=#{CGI.escape gen_values[1]}&edtLastName=&edtFirstName=&cboSex=0&cboRace=0&btnSearch=Search"
  end

  def paginated_body(gen_values, page)
    "__EVENTTARGET=GridView1&__EVENTARGUMENT=Page%24#{page}&__VIEWSTATE=#{CGI.escape gen_values[0]}&__VIEWSTATEGENERATOR=#{CGI.escape gen_values[2]}&__EVENTVALIDATION=#{CGI.escape gen_values[1]}&edtLastName=&edtFirstName=&cboSex=0&cboRace=0"
  end

  def prepare_inner_body(gen_values, page)
    "__EVENTTARGET=GridView1&__EVENTARGUMENT=%24#{page}&__VIEWSTATE=#{CGI.escape gen_values[0]}&__VIEWSTATEGENERATOR=#{CGI.escape gen_values[2]}&__EVENTVALIDATION=#{CGI.escape gen_values[1]}&edtLastName=&edtFirstName=&cboSex=0&cboRace=0"
  end
end
