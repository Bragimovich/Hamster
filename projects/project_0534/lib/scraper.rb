class Scraper < Hamster::Scraper
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end
  
  def get_request(url)
    retries = 0
    begin
      response = connect_to(url: url , proxy_filter: @proxy_filter)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    [response , response&.status]
  end

  
  private

  def reporting_request(response)
    if response.present?
      logger.info '=================================='.yellow
      logger.info 'Response status: '.indent(1, "\t").green
      status = "#{response.status}"
      logger.info response.status == 200 ? status.greenish : status.red
      logger.info '=================================='.yellow
    end
  end
  
end