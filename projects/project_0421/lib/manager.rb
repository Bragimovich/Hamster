# frozen_string_literal: true

# ------------------------- ATTENTION -------------------------------
# do not use "&firstname=". Use "&name=" because Faraday.new.get()
# sorts parameters in alphabetical order but target url don't mention
# param's name. Just param's order (index number)
#
# You need to place 'firstname=' after 'lastname=' in request,
# but params will be swapped because `f` is ahead of `l`.
# In other side 'n' goes after 'l' and in that case 'lastname'
# will be the first parameter and 'name' - the second one.
#
# see more here:    https://github.com/lostisland/faraday/issues/353

require_relative '../lib/parser'
require_relative '../lib/scraper'
require_relative '../lib/keeper'

HEADERS = {
  accept:                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
  accept_language:           'en-US,en;q=0.5',
  connection:                'keep-alive',
  upgrade_insecure_requests: '1'
}
CSV_NAME = "421-Records.csv"
WEBSITE_URL = "https://ecf.dcd.uscourts.gov/cgi-bin/attysrch.pl?lastname="
DEEP = 3      # max firstname letters
CONNECTION_ERROR_CLASSES =
  [
    ActiveRecord::ConnectionNotEstablished,
    Mysql2::Error::ConnectionError,
    ActiveRecord::StatementInvalid,
    ActiveRecord::LockWaitTimeout
  ]

class DCD_USCourtsGov < Hamster::Harvester
  def initialize
    super
    @parser = Parser.new
    @scraper = Scraper.new
  end

  def search_from_a_to_z(url, deep) # recurrent method
    return nil if deep == 0
    ('a'..'z').each do |fn|
      source_url = url + fn
      table = @parser.get_table_of_records(@scraper.get_source(source_url))
      if !!table
        @scraper.store_to_csv(@parser.parse_search_result(table, source_url))
      else
        search_from_a_to_z(source_url, deep.pred)
      end
    end
  end

  def parse
    ('a'..'z').each do |ln|
      source_url =  "#{WEBSITE_URL}#{ln}&name="
      search_from_a_to_z(source_url, DEEP)
    end
  rescue StandardError => e # SQLException => e
    logger.error(e)
  ensure
    logger.info("#{Time.now.to_s} Finish load data...")
  end

  def store
    csv_src = "#{@scraper.storehouse}store/#{CSV_NAME}"
    Keeper.new.store(csv_src)
    @scraper.clear # remove old *.csv to trash
  end
end
