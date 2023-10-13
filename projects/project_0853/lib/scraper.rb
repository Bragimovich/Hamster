require_relative 'parser'
require_relative 'connector'
class Scraper < Hamster::Scraper
  HOST = 'http://www.doc.state.al.us'
  SEARCH_URL = "#{HOST}/inmatesearch"
  DETAIL_URL = "#{HOST}/InmateInfo"
  def initialize
    super
    @connector = AlInmateConnector.new(HOST)
    @parser = Parser.new
  end

  def search_page
    @connector.do_connect(SEARCH_URL)
  end

  def search(form_data, page = 0)
    if page > 0
      @connector.do_connect(DETAIL_URL, method: :post, data: form_data)
    else
      @connector.do_connect(SEARCH_URL, method: :post, data: form_data)
    end
  end

  def detail_page(form_data)
    @connector.do_connect(DETAIL_URL, method: :post, data: form_data)
  end
end
