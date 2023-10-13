# frozen_string_literal: true
class Scraper < Hamster::Scraper
  MAIN_URL = "https://ia-plb.my.site.com/LicenseSearchPage"

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def main_page
    connect_to(MAIN_URL)
  end

  def post_page_request(body,cookie, state, city = '')
    connect_to(url: MAIN_URL, headers: get_headers(cookie), req_body: prepare_body(body, state, city), method: :post)
  end

  def paginate(body, cookie)
    connect_to(url: MAIN_URL, headers: get_headers(cookie) ,req_body: prepare_pagination_body(body), method: :post)
  end

  def fetch_link(link)
    connect_to(url: link)
  end

  private

  def prepare_body(body, state, city)
    "j_id0%3Aj_id1%3Aj_id14=j_id0%3Aj_id1%3Aj_id14&j_id0%3Aj_id1%3Aj_id14%3AfirstName=&j_id0%3Aj_id1%3Aj_id14%3AlicenseBoard=&j_id0%3Aj_id1%3Aj_id14%3AlastName=&j_id0%3Aj_id1%3Aj_id14%3AlicenseStatus=&j_id0%3Aj_id1%3Aj_id14%3AdisplayNameCertificate=&j_id0%3Aj_id1%3Aj_id14%3Acity=#{city.gsub(" ","+")}&j_id0%3Aj_id1%3Aj_id14%3Astate=#{state}&j_id0%3Aj_id1%3Aj_id14%3Azip=&j_id0%3Aj_id1%3Aj_id14%3AlastNameGroup=&j_id0%3Aj_id1%3Aj_id14%3Aj_id73=Search&j_id0%3Aj_id1%3Aj_id14%3AlicenseNumber=&com.salesforce.visualforce.ViewState=#{CGI.escape body[0]}&com.salesforce.visualforce.ViewStateVersion=#{CGI.escape body[1]}&com.salesforce.visualforce.ViewStateMAC=#{CGI.escape body[2]}"
  end

  def prepare_pagination_body(body)
    "j_id0%3Aj_id1%3Aj_id14=j_id0%3Aj_id1%3Aj_id14&j_id0%3Aj_id1%3Aj_id14%3Aj_id100=j_id0%3Aj_id1%3Aj_id14%3Aj_id100&com.salesforce.visualforce.ViewState=#{CGI.escape body[0]}&com.salesforce.visualforce.ViewStateVersion=#{CGI.escape body[1]}&com.salesforce.visualforce.ViewStateMAC=#{CGI.escape body[2]}"
  end

  def get_headers(cookie)
     {
      "Authority" => "ia-plb.my.site.com",
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
      "Accept-Language" => "en-US,en;q=0.9",
      "Cache-Control" => "max-age=0",
      "Cookie" => cookie,
      "Origin" => "https://ia-plb.my.site.com",
      "Referer" => "https://ia-plb.my.site.com/LicenseSearchPage",
      "Sec-Ch-Ua" => "\"Google Chrome\";v=\"107\", \"Chromium\";v=\"107\", \"Not=A?Brand\";v=\"24\"",
      "Sec-Ch-Ua-Mobile" => "?0",
      "Sec-Ch-Ua-Platform" => "\"Linux\"",
      "Sec-Fetch-Dest" => "document",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-Site" => "same-origin",
      "Sec-Fetch-User" => "?1",
      "Upgrade-Insecure-Requests" => "1",
      "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36",
     }
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      reporting_request(response)
      break if response&.status && [200, 304, 302, 307].include?(response.status)
    end
    response
  end

  def reporting_request(response)
    puts '=================================='.yellow
    print 'Response status: '.indent(1, '\t').green
    status = response.status.to_s
    puts response.status == 200 ? status.greenish : status.red
    puts '=================================='.yellow
  end
end
