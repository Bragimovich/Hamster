class Scraper < Hamster::Scraper
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {| response | ![200, 304].include?(response.status) || response.body.size.zero? }
  end

  def download_page(url)
    retries = 0
    begin
      Hamster.logger.debug "Processing URL -> #{url}".yellow
      response = connect_to(url: url , proxy_filter: @proxy_filter)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    [response , response&.status]
  end

  private 
 
  def reporting_request(response)
    if response.present?
      Hamster.logger.debug '=================================='.yellow
      Hamster.logger.info 'Response status: '.indent(1, "\t").green
      status = "#{response.status}"
      Hamster.logger.info status == 200 ? status.to_s.greenish : status.to_s.red
      Hamster.logger.debug '=================================='.yellow
    end
  end
end
