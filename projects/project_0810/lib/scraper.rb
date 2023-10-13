class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def mechanize_con
    @cobble = Dasher.new(:using=>:cobble)
  end

  def landing_page
    connect_to("https://www1.maine.gov/cgi-bin/online/mdoc/search-and-deposit/search.pl?Search=Continue")
  end

  def search_page
    connect_to(url: "https://www1.maine.gov/cgi-bin/online/mdoc/search-and-deposit/search.pl?Search=Continue", headers: search_headers, req_body: search_body, method: :post)
  end

  def results_page(cookie)
    headers = {}
    headers['Cookie'] = cookie
    connect_to(url: "https://www1.maine.gov/cgi-bin/online/mdoc/search-and-deposit/results.pl" , headers: header(cookie))
  end

  def get_inner_page(link)
    connect_to(link)
  end

  def pagination(cookie, next_url)
    connect_to(url: "https://www1.maine.gov/cgi-bin/online/mdoc/search-and-deposit/#{next_url}", headers: header(cookie))
  end

  def fetch_image(link)
    @cobble.get('https://www1.maine.gov' + link)
  end

  private

  def search_headers
    {
      "Content-Type": "application/x-www-form-urlencoded",
      "Origin": "https://www1.maine.gov",
      "Referer": "https://www1.maine.gov/cgi-bin/online/mdoc/search-and-deposit/search.pl?Search=Continue",
    }
  end

  def header(cookie)
    {
      "Cookie" => cookie,
      "Referer" => "https://www1.maine.gov/cgi-bin/online/mdoc/search-and-deposit/search.pl?Search=Continue", 
    }
  end

  def search_body
    "mdoc_number=&first_name=&middle_name=&last_name=&gender=&age_from=&age_to=&weight_from=&weight_to=&feet_from=&inches_from=&feet_to=&inches_to=&eyecolor=&haircolor=&race=&mark=&status=&location=&mejis_index=&submit=Search"
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304,302].include?(response.status)
    end
    response
  end
end
