require_relative 'connector'
class Scraper < Hamster::Scraper
  HOST = 'https://jailregister.sno911.org'
  BASE_URL = "#{HOST}/SCSO"
  def initialize
    super
    @connector = WaInmateConnector.new(BASE_URL)
    @from_date = '2000-06-01'.to_date
    @to_date = Date.today
  end

  def search_result(page)
    params = {
      'BookingFromDate' => @from_date.strftime('%m-%d-%Y'),
      'BookingToDate' => @to_date.strftime('%m-%d-%Y'),
      'Page' => page.to_s
    }
    query = params.map{|key, val| "#{CGI.escape(key)}=#{CGI.escape(val)}"}.join('&')
    url = "#{BASE_URL}?#{query}"
    response = @connector.do_connect(url)
  rescue => e
    logger.info "========= not found page(#{url}) ============"
    nil
  end

  def detail_page(detail_page_url)
    @connector.do_connect(detail_page_url)
  rescue => e
    logger.info "========= not found page(#{detail_page_url}) ============"
    nil
  end
end
