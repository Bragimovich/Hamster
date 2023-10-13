class Scraper < Hamster::Scraper

  def download(link)
    url  = connect_to(link, proxy_filter: @proxy_filter, ssl_verify: false)
    json = JSON.parse(url.body)
  end
end
