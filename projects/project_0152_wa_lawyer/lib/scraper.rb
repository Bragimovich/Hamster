class Scraper < Hamster::Scraper
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def download_page(url)
    headers = {
      "GET" => "/PersonifyEbusiness/Default.aspx?TabID=1536&ShowSearchResults=TRUE&FirstName=a HTTP/1.1",
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
      "Accept-Encoding" => "gzip, deflate, br",
      "Accept-Language" => "en-US,en;q=0.9",
      "Cache-Control" => "no-cache",
      "Connection" => "keep-alive",
      "Cookie" => ".ASPXANONYMOUS=FTe7QZj42AEkAAAAYmFhZTc1ZTEtNmM0Mi00NGQ5LTllYzEtOTIwMmIwNDllMWQ30; ASP.NET_SessionId=0tm0wk30vra3332t0gvgj2mz; language=en-US; AnonumousTimssCMSUser=0tm0wk30vra3332t0gvgj2mz; __utmc=48064059; __utmz=48064059.1662478590.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none); __utma=48064059.2031807232.1662478590.1662478590.1662774903.2",
      "Host" => "www.mywsba.org",
      "Pragma" => "no-cache",
      "Sec-Fetch-Dest" => "document",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-Site" => "none",
      "Sec-Fetch-User" => "?1",
      "Upgrade-Insecure-Requests" => "1",
      "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36",
      "sec-ch-ua" => "'Chromium';v='104', ' Not A;Brand';v='99', 'Google Chrome';v='104'",
      "sec-ch-ua-mobile" => "?0",
      "sec-ch-ua-platform" => "Linux"
    }

    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = connect_to(url: url , proxy_filter: @proxy_filter, headers: headers)
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