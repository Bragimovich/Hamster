class Scraper < Hamster::Scraper
  
  def fetch_cookies
    url = 'https://propublic.buckscountyonline.org/PSI/auth?ReturnUrl=%2fPSI%2fv%2fsearch%2fcase%3fQ%3d%26IncludeSoundsLike%3dfalse%26Count%3d20%26fromAdv%3d1%26CaseNumber%3d%26LegacyCaseNumber%3d%26ParcelNumber%3d%26CaseType%3d%26DateCommencedFrom%3d%26DateCommencedTo%3d%26FilingType%3d%26FilingDateFrom%3d%26FilingDateTo%3d%26Court%3dC%26Court%3dF%26JudgeID%3d%26Attorney%3d%26AttorneyID%3d%26Grid%3dtrue&Q=&IncludeSoundsLike=false&Count=20&fromAdv=1&CaseNumber=&LegacyCaseNumber=&ParcelNumber=&CaseType=&DateCommencedFrom=&DateCommencedTo=&FilingType=&FilingDateFrom=&FilingDateTo=&Court=C&Court=F&JudgeID=&Attorney=&AttorneyID=&Grid=true'
    connect_to(url)
  end

  def main_page_request(cookie, key, date)
    url = "https://propublic.buckscountyonline.org/PSI/v/search/case?Q=#{key}&IncludeSoundsLike=false&Count=1000&fromAdv=1&CaseNumber=&LegacyCaseNumber=&ParcelNumber=&CaseType=&DateCommencedFrom=&DateCommencedTo=&FilingType=&FilingDateFrom=#{get_date(date)}&FilingDateTo=#{get_date(date)}&JudgeID=&Attorney=&AttorneyID=&Grid=true"
    headers_value = {}
    headers_value["Cookie"] = cookie
    response = connect_to(url: url, headers: headers_value)
    [response, url]
  end

  def inner_page_request(url, cookie, main_url)
    headers_value = {}
    headers_value["Cookie"] = cookie
    headers_value["Origin"] = 'https://propublic.buckscountyonline.org'
    headers_value["Referer"] = url
    form_data = get_form_data
    form_data = form_data.to_a.map { |val| val[0] + "=" + val[1] }.join("&")
    connect_to(url: "#{url}/data", req_body: form_data, headers: headers_value, method: :post)
  end

  private

  def get_date(date)
    CGI.escape date.split('-').rotate.join('/')
  end

  def get_form_data
    {
      "DocketRange" => "50",
      "token" => ""
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

end
