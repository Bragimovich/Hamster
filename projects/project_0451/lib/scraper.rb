require_relative 'parser'
require_relative 'keeper'

class Scraper < Hamster::Scraper
  
  BASE_URL = "https://www.opensocietyfoundations.org/grants/past?page="
  SUB_FOLDER = 'open_society_foundations'

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def download_web_page(url, inner = false)
    retries = 0
    begin
      puts "Processing URL #{inner} -> #{url}".yellow
      response = Hamster.connect_to(url: url , proxy_filter: @proxy_filter)
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
  