require 'nokogiri'
require 'uri'
require_relative 'connector'
require_relative 'parser'

class Scraper < Hamster::Scraper
  HOST             = 'https://civilwebshopping.occourts.org'
  START_PAGE       = "#{HOST}/Home.do"
  SEARCH_PAGE      = "#{HOST}/Search.do#searchAnchor"
  SEARCH_DATE_PAGE = "#{HOST}/SearchDate.do"
  SEARCH_CASE_PAGE = "#{HOST}/SearchCase.do"
  VIEW_PARTY_PAGE  = "#{HOST}/ViewEserved.do"

  def initialize(year = 2023)
    super
    @year = year
    @parser = Parser.new
    @connector = CaOcscCaseConnector.new(START_PAGE)
  end

  def scrape
    cases_count = 0
    start_date = Date.new(@year, 1, 1)
    end_date_of_year = Date.new(@year, 12, 31)
    response = @connector.do_connect(SEARCH_PAGE)
    over_founds = false # we have to change the date range, if found 1000 records
    store_path = store_file_path()
    loop do
      range_list = [3, 2, 1]
      default_range = 6.days
      retry_count = 0
      cases = []
      begin
        end_date = start_date + default_range
        end_date = end_date_of_year if end_date.month == 12 && ([28, 29, 30].include?(end_date.day))
        end_date = end_date_of_year if end_date > end_date_of_year

        break if @year < start_date.year || Date.today < start_date
        break if (start_date..end_date).include?(Date.today)

        file_path = "#{store_path}/#{start_date.strftime('%m-%d')}_#{end_date.strftime('%m-%d')}.dat"
        if File.exist?(file_path)
          logger.info "Skipping #{file_path}"
          start_date = end_date + 1.day

          next 
        end

        form_data = form_data(start_date, end_date)        
        response = @connector.do_connect(SEARCH_DATE_PAGE, data: form_data, method: :post)
        cases = @parser.parse_cases(response.body)

        if cases.length.zero?
          default_range = default_range + 2.days
          raise "Not found records with #{start_date.strftime('%m/%d/%Y')}_#{end_date.strftime('%m/%d/%Y')}"
        elsif cases.count > 999
          range = range_list.shift
          if range
            default_range = range.days
            raise "Found over records with #{start_date.strftime('%m/%d/%Y')}_#{end_date.strftime('%m/%d/%Y')}"
          end
        end
      rescue StandardError => e
        logger.info e.full_message
        raise e if retry_count > 2

        retry_count += 1

        retry
      end
      
      store_case_ids(file_path, cases)
      logger.info("Scraped cases(#{cases.count}) to -> #{file_path}\n")

      start_date = end_date + 1.day
      cases_count += cases.count
      break if @year < start_date.year || Date.today < start_date
    end
    Hamster.report(to: 'U04JS3K201J', message: "project_0738: Scraped all cases: #{@year} - #{cases_count}")
  end

  private

  def form_data(st_date, ed_date)
    {
      'startFilingDate' => st_date.strftime('%m/%d/%Y'),
      'endFilingDate' => ed_date.strftime('%m/%d/%Y'),
      'g-recaptcha-response' => '',
      'action' => 'Search'
    }
  end

  def store_case_ids(file_path, case_data)
    File.open(file_path, 'w+') do |f|
      f.puts(case_data.uniq)
    end
  end

  def store_file_path
    store_path = "#{storehouse}store/#{@year}"
    FileUtils.mkdir_p(store_path)
    store_path
  end
end
