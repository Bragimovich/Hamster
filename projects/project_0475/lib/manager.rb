# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

URL = 'https://www.scbar.org'
WEBSITE_URL = "#{URL}/lawyers/directory/list/?last_name=a"
JUDGE_DREDD = "#{URL}/lawyers/directory/profile/93083"
CSV_NAME = 'scbar_org.csv'
CONNECTION_ERROR_CLASSES =
  [
    ActiveRecord::ConnectionNotEstablished,
    Mysql2::Error::ConnectionError,
    ActiveRecord::StatementInvalid,
    ActiveRecord::LockWaitTimeout
  ]

class SCBAR_Manager < Hamster::Harvester
  def initialize
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def parse
    @scraper.clear # remove old *.csv to trash
    @scraper.good_proxies # create a list of proxies working with this url
    links = []
    page_num = 0
    loop do
      page_num += 1
      url = "#{WEBSITE_URL}&page=#{page_num}"

      retry_count = 5 # sometime get_source returns an empty page
      begin
        retry_count -= 1
        source = @scraper.get_source(url)
        4.times do
          break if @parser.next?(source)
          source = @scraper.get_source(url)
        end
        links = @parser.parse_links(source)
      rescue links[0][0]
        retry if retry_count > 0
      end

      links.each do |url|
        next if url == JUDGE_DREDD
        response = @scraper.get_source(url)
        next unless response.status == 200
        @scraper.store_to_csv([@parser.parse_member(response)], CSV_NAME)
      end
      break unless @parser.next?(source)
    end
  end

  def store
    csv_src = "#{@scraper.storehouse}store/#{CSV_NAME}"
    Keeper.new.store(csv_src)
    @scraper.clear # remove old *.csv to trash
  end

  def fix
    @keeper.fix_table.split(';').each {|sql| @keeper.run_sql(sql)}
  end
end
