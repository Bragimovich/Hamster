require_relative 'connector'
require_relative 'parser'
require 'date'

class Scraper < Hamster::Scraper
  START_PAGE      = 'https://www.la3circuit.org/index.aspx#searchRecords'
  SEARCH_PAGE     = 'https://www.la3circuit.org/index.aspx'

  def initialize(year)
    super
    @year      = year
    @parser    = Parser.new
    @connector = CirCuitConnector.new(START_PAGE)
  end

  def scrape(&block)
    raise 'Block must be given' unless block_given?

    main_page = @connector.do_connect(SEARCH_PAGE)
    Date::MONTHNAMES.compact.each do |month|
      form_fields = @parser.extract_form_fields(main_page, @year, month)
      response    = @connector.do_connect(SEARCH_PAGE, data: form_fields, method: :post)
      opinions    = @parser.parse_opinions(response)
      @logger.info("=========#{month}/#{@year} : Scraped: #{@parser.scraped_ids.join(',')}")
      opinions.each(&block)
    end
  end
end
