class Scraper < Hamster::Scraper
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end
  
  def get_request(url)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = connect_to(url: url , proxy_filter: @proxy_filter)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    [response , response&.status]
  end

  def get_page_with_id(id)
    url = "https://attorneyinfo.aoc.arkansas.gov/info/attorney/Attorney_Search_Detail.aspx?ID=#{id}"
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = connect_to(url: url , proxy_filter: @proxy_filter)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    [response , response&.status]
  end

  def post_request(url,form_data,cookie,ajax_request = false)
    headers = {
      "Cookie": set_cookie(cookie),
      "Connection": "keep-alive",
      "Host": "attorneyinfo.aoc.arkansas.gov",
      "Origin": "https://attorneyinfo.aoc.arkansas.gov",
      "Referer": "https://attorneyinfo.aoc.arkansas.gov/info/attorney/attorneysearch.aspx",
      "Content-Type" =>  "application/x-www-form-urlencoded; charset=UTF-8",
      "Pragma": "no-cache",
      "sec-ch-ua-mobile": "?0",
      "sec-ch-ua-platform": "Linux",
      "Sec-Fetch-Dest": "empty",
      "Sec-Fetch-Mode": "cors",
      "Sec-Fetch-Site": "same-origin",
      "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.102 Safari/537.36 OPR/90.0.4480.84"
    }
    if ajax_request
      headers["X-MicrosoftAjax"] = "Delta=true"
      headers["X-Requested-With"] = "XMLHttpRequest"
    end
  
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = connect_to(url: url , proxy_filter: @proxy_filter, method: :post, headers: headers, req_body: form_data)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    [response , response&.status]
  end
  
  private

  def set_cookie(raw_cookie)
    list = ['ASP.NET_SessionId','__RequestVerificationToken','AnonymousCartId','BIGipServerPROD_imis']
    cookies_list = []
    raw_cookie.split(";").each do |i|
      list.each do |l|
        if i.include?(l)
          cookies_list << i
        end
      end
    end
    _cookie = ""
    cookies_list.each do |cookie|
      cookie = cookie.gsub(' SameSite=Lax,','')
      cookie = cookie.gsub(' HttpOnly,','')
      _cookie += cookie
      _cookie += ";"
    end
    _cookie += ' Asi.Web.Browser.CookiesEnabled=true'
    _cookie
  end

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