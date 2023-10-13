require_relative 'wisc_courts_parser'
require_relative '../modules/abstract_scraper'

class WiscCourtsScraper < Hamster::Scraper
  include ExtConnectTo
  HOST        = 'https://wscca.wicourts.gov/'.freeze
  START_DATE  = Date.today - Date.today.mday + 1
  END_DATE    = "#{START_DATE.year - 3}-01-01".to_date
  COURT_TYPES = %w[CA SC].freeze
  DISTRICTS   = [1, 2, 3, 4].freeze

  def initialize(keeper)
    super
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
    @keeper       = keeper
    @count_new    = 0
    @count_open   = 0
    init_var
  end

  attr_reader :count_new, :count_open

  def response(link)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    connect_to(url: link, proxy_filter: @proxy_filter, ssl_verify: false)
  end

  def scrape_new_case
    COURT_TYPES.each do |court_type|
      DISTRICTS.each do |district|
        start_date = START_DATE
        12.times do
          url = "#{HOST}caseSearch.do?action=Search&countyNo=0&courtType=#{court_type}&district=#{district}" \
                "&filingDateRange=30&recordsPerPage=50&filingDate.dateString=#{start_date.strftime('%m-%d-%Y')}"
          offset      = 0
          search_page = response(url)
          cache_id    = search_page.env.url.to_s.split('?')[-1].split('&')[0]
          loop do
            link      = "#{HOST}pager.do?#{cache_id}&offset=#{offset}&sortColumn=0&sortDirection=DESC"
            link_body = response(link)&.body
            parser    = WiscCourtsParser.new(link_body)
            cases     = parser.list
            cases.each do |case_id|
              next if keeper.case_exists?(case_id)

              save_case(case_id)
              save_activities(case_id)
              @count_new += 1
            end
            break if cases.size < 50

            offset += 50
          end
          start_date = start_date.prev_month
        end
      end
    end
  end

  def scrape_open_case
    open_case = keeper.get_open_case
    open_case.each do |i|
      save_case(i)
      save_activities(i)
      @count_open += 1
    end
  end

  def get_pdf(link)
    link = link.sub('http://', 'https://')
    if link.match?(%r{other/appeals/caopin|supreme/scopin})
      page   = response(link)&.body
      parser = WiscCourtsParser.new(page)
      link   = parser.get_link_pdf
    end
    response(link)&.body
  end

  def get_pdf_dasher(url)
    Dasher.new(using: :cobble).get(url)
  end

  private

  attr_reader :keeper

  def save_case(case_id)
    link         = "#{HOST}caseDetails.do?caseNo=#{case_id}"
    case_details = response(link)&.body
    peon.put(file: case_id, content: case_details, subfolder: "#{keeper.run_id}_case")
  end

  def save_activities(case_id)
    link       = "#{HOST}appealHistory.xsl?caseNo=#{case_id}"
    activities = response(link)&.body
    peon.put(file: "#{case_id}_history", content: activities, subfolder: "#{keeper.run_id}_case_history")
  end
end
