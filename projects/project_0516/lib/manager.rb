# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/helper'

URL = 'https://www.ncappellatecourts.org/'
DOCKET_URL_PREFIX = 'https://appellate.nccourts.org/dockets.php?pdf=1&a=0&dev=1'
SEARCH_URL = "#{URL}search-results.php?"
TEST_CASE = '2-2000-9999-001.pdf'
CONNECTION_ERROR_CLASSES =
  [
    ActiveRecord::ConnectionNotEstablished,
    Mysql2::Error::ConnectionError,
    ActiveRecord::StatementInvalid,
    ActiveRecord::LockWaitTimeout
  ]
# full_url = "#{SEARCH_URL}atty_first=&atty_last=&sDocketSearch=&short_title=&party=&start_date=#{interval[:begin_str]}&end_date=#{interval[:end_str]}&type=&court_name=&bSearchTypeAnd=1&exact=0"

class NCSaacCaseManager < Hamster::Harvester
  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @helper = Helper.new
  end

# =========================== DOWNLOAD block ===========================
  def download(**options)
    @scraper.clear
    interval = week_interval(options[:weeks_ago])
    compact_url = "#{SEARCH_URL}start_date=#{interval[:begin_str]}&end_date=#{interval[:end_str]}"
    links = get_links(compact_url)
    links_to_download = options[:update] ? links[:all] : links[:new]
    links_to_download.each {|el| logger.info(el)}

    @scraper.download(links_to_download)
  end

  # --------------- auxiliary methods ---------------

  def week_interval(weeks_ago)
    day = Date.today - 7 * weeks_ago.to_s.to_i
    interval_to_s(day.beginning_of_week, day.end_of_week.next_day)
  end

  def interval_to_s(begin_date, end_date)
    {begin_str: begin_date.strftime("%m/%d/%Y"),
       end_str: end_date.strftime("%m/%d/%Y")}
  end

  def get_links(url)
    links = []
    loop do
      links += @parser.parse_links(@scraper.get_source(url))
      break if links.empty? || links.last.include?('dockets.php')
      url = links.pop # the last link contains the path to the next page with links
    end
    res = links.uniq.map {|el| el.sub('http:','https:')}.each_slice(2).to_a
    links_to_groups(res)
  end

  def links_to_groups(all_links)
    cases_in_db_links = @keeper.cases_in_db_links;
    new_links = all_links.reject {|el| el.first.in?(cases_in_db_links)}
    links = { all: all_links,
              new: new_links,
              xst: all_links - new_links}
    logger.info("#{STARS}" +
      "\nAll links: #{links[:all].size}" +
      "\nNew links: #{links[:new].size}" +
      "\nXst links: #{links[:xst].size}#{STARS}")
    links
  end
# ========================= DOWNLOAD block ends =========================

# ============================= PARSE block =============================
  def parse
    pdf_list = @scraper.pdf_list
    # pp res = pdf_list[0,1].map {|pdf| parse_pdf(pdf)}.compact
    pdf_list[..-1].each {|pdf| @scraper.store_all_to_csv(parse_pdf(pdf))}
    # pdf_list[0,1].each {|pdf| @scraper.store_all_to_csv(parse_pdf(pdf))}
  end

  # --------------- auxiliary methods ---------------

  def parse_pdf(pdf)
    parse_result = @parser.parse_txt(@scraper.pdf_to_txt(pdf))
    parse_result[:links] = links(parse_result, pdf)

    dockets_info = @parser.parse_dockets_info(@scraper.dockets_info(pdf))
    parse_result = @helper.merge_activities_with_links(parse_result, dockets_info)
    parse_result = @helper.add_additional(parse_result)
  rescue StandardError => e
    [STARS,  e].each {|line| logger.error(line)}
    return nil
  end

  def links(case_hash, pdf_path)
    filename = pdf_path.split('/').last
    court = filename.split('-').first
    docket = filename.split('.').first

    pdf_link = "#{DOCKET_URL_PREFIX}&court=#{court}&docket=#{docket}"
    key_start = "us_courts_#{case_hash[:info][:court_id]}_#{case_hash[:info][:case_id]}_#{docket}_"
    dockets_page = @scraper.dockets_info(pdf_path)
    {
      source_link:      pdf_link,
      aws_link:         @scraper.save_to_aws(pdf_link, key_start),
      data_source_url:  @parser.dockets_source_url(dockets_page)
    }
  end
# =========================== PARSE block ends ===========================

# ============================= STORE block =============================
  def store(update_flag)
    csv_path = "#{@scraper.storehouse}store/csv/"
    @keeper.store(csv_path, update_flag)
    @scraper.clear
  end
# =========================== STORE block ends ===========================

  def test
    # pp @keeper.get_pdf_md5_hash('1000PA90')
    # pp cases = @keeper.all_cases_this_run(true)
    # puts "(#{cases.to_s.gsub('"','\'')[1..-2]})"
  end
end
