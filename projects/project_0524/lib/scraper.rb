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
      begin
        response = connect_to(url: url , proxy_filter: @proxy_filter, ssl_verify: false)
      rescue NoMethodError
        return [nil, 404]
      end
      reporting_request(response)
      if [301, 302].include? response&.status
        url = response.headers["location"]
        puts "URL is redirected to -> #{url}".yellow
        regex = "^(http|https|www)"
        unless url&.match(regex)&.present?
          return [nil, 404]
        end
        response = connect_to_prime(url)
        return [response[0] , response[1]]
      end
      retries += 1
    end until response&.status == 200 or retries == 10
    [response , response&.status]
  end

  def connect_to_prime(url)
    # function to parse redirected url
    retries = 0
    begin
      puts "Processing Redirected URL -> #{url}".red
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter )
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    return [response , response&.status]
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