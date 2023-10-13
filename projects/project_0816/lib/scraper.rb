class Scraper < Hamster::Scraper

  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  def initialize
    super
    @cobble = Dasher.new(:using=>:cobble)
  end

  def fetch_main_page
    connect_to("https://coms.doc.state.mn.us/PublicViewer/Home/Index?id")
  end

  def post_req(cookie, token, f_name, l_name)
    body = prepare_body(token, f_name, l_name)
    connect_to(url: "https://coms.doc.state.mn.us/PublicViewer/Home/Index", headers: post_request_headers(cookie) , req_body: body , method: :post)
  end

  def get_req(cookie)
    connect_to(url: "https://coms.doc.state.mn.us/PublicViewer/SearchResults/GetOffenders////1?filterscount=0&groupscount=0&pagenum=0&pagesize=5&recordstartindex=0&recordendindex=18&_=#{(Time.now.to_f*1000).to_i}", headers: post_request_headers(cookie))
  end

  def get_inner_link_page(oid, cookie)
    link = (oid.include?("https://coms.doc.state.mn.us/publicviewer")) ? oid : "https://coms.doc.state.mn.us/publicviewer/OffenderDetails/Index/#{oid}/Search"
    connect_to(url: link, headers: inner_link_headers(cookie))
  end

  def get_phone_link_page(link)
    @cobble.get(link)
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

  def inner_link_headers(cookie)
    {
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "Accept-Language" => "en-US,en;q=0.9",
      "Cache-Control" => "max-age=0",
      "Connection" => "keep-alive",
      "Cookie" => cookie,
      "Sec-Fetch-Dest" => "document",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-Site" => "none",
      "Sec-Fetch-User" => "?1",
      "Upgrade-Insecure-Requests" => "1",
      "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
      "Sec-Ch-Ua" => "\"Google Chrome\";v=\"113\", \"Chromium\";v=\"113\", \"Not-A.Brand\";v=\"24\"",
      "Sec-Ch-Ua-Mobile" => "?0",
      "Sec-Ch-Ua-Platform" => "\"Linux\"",
    }
  end

  def get_headers(cookie)
  {
    "Accept" => "application/json, text/javascript, */*; q=0.01",
    "Accept-Language" => "en-US,en;q=0.9",
    "Connection" => "keep-alive",
    "Cookie" => cookie,
    "Referer" => "https://coms.doc.state.mn.us/PublicViewer/SearchResults",
    "Sec-Fetch-Dest" => "empty",
    "Sec-Fetch-Mode" => "cors",
    "Sec-Fetch-Site" => "same-origin",
    "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
    "X-Requested-With" => "XMLHttpRequest",
    "Sec-Ch-Ua" => "\"Google Chrome\";v=\"113\", \"Chromium\";v=\"113\", \"Not-A.Brand\";v=\"24\"",
    "Sec-Ch-Ua-Mobile" => "?0",
    "Sec-Ch-Ua-Platform" => "\"Linux\""
  }
  end

  def post_request_headers(cookie)
    {
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "Accept-Language" => "en-US,en;q=0.9",
      "Cache-Control" => "max-age=0",
      "Connection" => "keep-alive",
      "Cookie" => cookie,
      "Origin" => "https://coms.doc.state.mn.us",
      "Referer" => "https://coms.doc.state.mn.us/PublicViewer/Home/Index?id=1",
      "Sec-Fetch-Dest" => "document",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-Site" => "same-origin",
      "Sec-Fetch-User" => "?1",
      "Upgrade-Insecure-Requests" => "1",
      "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
      "Sec-Ch-Ua" => "\"Google Chrome\";v=\"113\", \"Chromium\";v=\"113\", \"Not-A.Brand\";v=\"24\"",
      "Sec-Ch-Ua-Mobile" => "?0",
      "Sec-Ch-Ua-Platform" => "\"Linux\"",
    }
  end

  def prepare_body(token, f_name, l_name)
    "__RequestVerificationToken=#{token}&rdogrp=1&firstName=#{f_name}&lastName=#{l_name}&oid="
  end

end
