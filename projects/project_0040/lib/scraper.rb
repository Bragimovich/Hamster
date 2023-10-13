class Scraper < Hamster::Scraper

  def initialize()
    super
  end

  def first_page_headers
    {
      "Connection" => "keep-alive",
      "Cache-Control" => "max-age=0",
      "Sec-Ch-Ua" => "\"Google Chrome\";v=\"89\", \"Chromium\";v=\"89\", \";Not A Brand\";v=\"99\"",
      "Sec-Ch-Ua-Mobile" => "?0",
      "Upgrade-Insecure-Requests" => "1",
      "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36",
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
      "Sec-Fetch-Site" => "none",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-User" => "?1",
      "Sec-Fetch-Dest" => "document",
      "Accept-Language" => "en-US,en;q=0.9",
    }
  end

  def data_request_headers(cookie)
    {
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
      "Accept-Language" => "en-US,en;q=0.9",
      "Connection" => "keep-alive",
      "Cookie" => cookie,
      "Referer" => "https://revenue.delaware.gov/business-license-search/",
      "Sec-Fetch-Dest" => "document",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-Site" => "same-origin",
      "Sec-Fetch-User" => "?1",
      "Upgrade-Insecure-Requests" => "1",
      "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36",
      "Sec-Ch-Ua" => "\"Chromium\";v=\"104\", \" Not A;Brand\";v=\"99\", \"Google Chrome\";v=\"104\"",
      "Sec-Ch-Ua-Mobile" => "?0",
      "Sec-Ch-Ua-Platform" => "\"Linux\"",
    }
  end

  def get_first_page
    url =  "https://revenue.delaware.gov/business-license-search/"
    connect_to(url: url, headers: first_page_headers)
  end

  def get_data_request(cookie,page_no)
    if page_no == 1
      url =  "https://revenue.delaware.gov/business-license-search/"
    else
      url = "https://revenue.delaware.gov/business-license-search/page/#{page_no}/"
    end
    connect_to(url: url, headers: data_request_headers(cookie))&.body    
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      reporting_request(response)
      break if response&.status && [200, 304,302].include?(response.status)
    end
    response
  end

  def reporting_request(response)
    puts '=================================='.yellow
    print 'Response status: '.indent(1, "\t").green
    status = response&.status
    puts status == 200 ? status.to_s.greenish : status.to_s.red
    puts '=================================='.yellow
  end

end
