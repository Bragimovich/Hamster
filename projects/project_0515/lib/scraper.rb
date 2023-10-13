class Scraper < Hamster::Scraper
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def get_request(url,payload)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      headers = {
        "Accept": "application/json",
        "Accept-Language": "en-US,en;q=0.9",
        "Host": "data.cdc.gov",
        "Referer": "https://data.cdc.gov/NCHS/Weekly-Provisional-Counts-of-Deaths-by-State-and-S/muzy-jte6",
        "X-Requested-With": "XMLHttpRequest",
        "X-Socrata-Federation": "Honey Badger"
      }
      response = connect_to(url: url , proxy_filter: @proxy_filter, form_data: payload, headers: headers)
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