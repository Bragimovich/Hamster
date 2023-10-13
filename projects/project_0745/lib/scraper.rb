class Scraper < Hamster::Scraper
  def scrape(link, query)
    form_data = "__VIEWSTATE=%2FwEPDwUKLTYwNjY5NTU3NA9kFgJmD2QWAgIDD2QWAgIBD2QWBAIBDw9kFgIeBXN0eWxlBQ9kaXNwbGF5OmlubGluZTsWBAIFDw9kFgIeB29uY2xpY2sFEXJldHVybiBmY25DaGVjaygpZAIHDxYCHwAFNHdpZHRoOjEwMCU7dGV4dC1hbGlnbjpjZW50ZXI7Y29sb3I6UmVkO2Rpc3BsYXk6bm9uZTtkAgMPD2QWAh8ABQ1kaXNwbGF5Om5vbmU7ZGTTaKUuxo7RSC5m5Cj%2B79e1TTkQfGqqm%2BIxHsGbSL%2F7Vg%3D%3D&__VIEWSTATEGENERATOR=E80E49F3&__EVENTVALIDATION=%2FwEdAASUnUSegbDePjQX6LYomDZlPgOhcVkiU1VTWf02mANGwxdjcOFr6BdsJcsxH7jpJDI00J7jzvdM3BDYFTrGYk5xveaMuw11UBBFyizbXq6xh3qB88TO5WbiUP6nmN6cmuk%3D&ctl00%24cphMain%24txtLName=#{query}&ctl00%24cphMain%24txtFName=&ctl00%24cphMain%24btnSubmit=Search"
    site = connect_to(link,
                      proxy_filter: @proxy_filter,
                      ssl_verify:   false,
                      method:       :post,
                      req_body:     form_data
    )
    site_body = Nokogiri::HTML5(site.body)
  end
end
