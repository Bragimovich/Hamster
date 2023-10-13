class Scraper <  Hamster::Scraper
  
  def connect_to(url)
    retries = 0
    begin
      response = Hamster.connect_to(url: url , proxy_filter: @proxy_filter)
      retries += 1
    end until response&.status == 200 or response&.status == 404 or retries == 10
    response.body
  end
end
