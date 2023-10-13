class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def download_page(url)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = connect_to(url: url , proxy_filter: @proxy_filter)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    [response , response&.status]
  end

  def set_cookie(raw_cookie)
    @cookie = {}
    return if raw_cookie.nil?
    raw = raw_cookie.split(";").map do |item|

      if item.include?("Expires=")
        item.split("=")
        ""
      else
        item.split(",")
      end

    end.flatten
    raw.each do |item|
      if !item.include?("Path") && !item.include?("HttpOnly")  && !item.include?("Secure") && !item.empty?
        name, value = item.split("=")
        @cookie.merge!({"#{name}" => value})
      end
    end
    @cookie.map {|key, value| "#{key}=#{value}"}.join(";")
  end

  def download_Page(url, cookie)
    headers = {
      "Host": "dw.courts.wa.gov",
      "User-Agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:102.0) Gecko/20100101 Firefox/102.0",
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
      "Accept-Language": "en-US,en;q=0.5",
      "Referer": "https://dw.courts.wa.gov/index.cfm?fa=home.caselist&amp;init&amp;rtlist=case",
      "Connection": "keep-alive",
      "Cookie": set_cookie(cookie),
      "Upgrade-Insecure-Requests": "1",
      "Sec-Fetch-Dest": "document",
      "Sec-Fetch-Mode": "navigate",
      "Sec-Fetch-Site": "same-origin",
      "Sec-Fetch-User": "?1",
      "Pragma": "no-cache",
      "Cache-Control": "no-cache",
    }
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = connect_to(url: url , proxy_filter: @proxy_filter , headers: headers)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    [response , response&.status]
  end

  def download_page_with_post_request(url ,form_data)
    retries = 0
    begin
      puts "Processing URL (POST REQUEST) -> #{url}".yellow
      response = connect_to(url: url, proxy_filter: @proxy_filter ,method: :post , req_body: form_data)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    [response , response&.status]
  end

  private

  def reporting_request(response)
    if response.present?
      puts '=================================='.yellow
      print 'Response status: '.indent(1, "\t").green
      status = "#{response.status}"
      puts response.status == 200 ? status.greenish : status.red
      puts '=================================='.yellow
    end
  end
end