class Scraper <  Hamster::Scraper
  
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def main_page_get
    Hamster.connect_to("https://salaries.myflorida.com")
  end

  def download_file(cookie_value,link)
    headers = {}
    headers["Cookie"] = cookie_value
    url = "https://salaries.myflorida.com#{link}"
    Hamster.connect_to(url: url, headers: headers)
  end
end
