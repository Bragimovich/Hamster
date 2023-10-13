class Scraper < Hamster::Scraper
  def initialize
    super
    @cobble = Dasher.new(using: :cobble)
  end

  URL = 'http://www.eccorrections.org/inmatelookup'

  def main_page
      connect_to(URL)
  end

  def get_image(url)
     connect_to("http://www.eccorrections.org/#{url}")  { |resp| resp.headers["server"]&.match?(%r{WildFly/10}) } #Content-Type: image/jpeg
  end

  def inner_page(cookie, pagination, counter = nil)
    if pagination
       body = "flow_action=next&currentStart=#{counter}"
    else
      body = 'flow_action=searchbyid&quantity=10&systemUser_identifiervalue=&searchtype=PIN&systemUser_includereleasedinmate=&systemUser_includereleasedinmate2=N&systemUser_firstName=&systemUser_lastName=&systemUser_dateOfBirth=&identifierbox=PIN&identifier='
    end
    headers = get_headers(cookie)
    connect_to(URL, headers: headers, req_body:body, method: :post)
  end

  def data_page(body_info, cookie)
    body = "flow_action=edit&sysID=#{body_info.split("','")[0]}&imgSysID=#{body_info.split("','")[1]}"
    headers = get_headers(cookie)
    connect_to(URL, headers: headers, req_body:body, method: :post)
  end

  def get_headers(cookie)
      {
        "Content-type" => "application/x-www-form-urlencoded",
        "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
        "Accept-Language" => "en-US,en;q=0.9",
        "Cache-Control" => "no-cache",
        "Cookie" => cookie,
        "Origin" => "http://www.eccorrections.org",
        "Pragma" => "no-cache",
        "Proxy-Connection" => "keep-alive",
        "Referer" => "http://www.eccorrections.org/inmatelookup",
        "Upgrade-Insecure-Requests" => "1",
        "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36"
        
      }
  end
end
