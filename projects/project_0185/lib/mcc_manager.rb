require_relative 'mcc_keeper'
require_relative 'mcc_parser'
require_relative 'mcc_scraper'

class MccManager < Hamster::Harvester
  SLACK_ID  = 'Eldar Eminov'

  def download
    scraper = MccScraper.new
    scraper.scrape
  rescue StandardError => error
    report_error(error)
  end

  def store
    names    = peon.give_list
    keeper   = MccKeeper.new
    links_db = keeper.links
    names.each do |name|
      page = peon.give(file: name)
      date = Date.parse(peon.give(file: name.sub('.gz', '.txt.gz'), subfolder: 'slideshows')) if name.match?(/slides/)
      parser   = MccParser.new(html: page)
      one_news = parser.parse_new_data(links_db, date)
      keeper.save_news(one_news)
    end
  rescue => error
    report_error(error)
  end

  private

  def report_error(error)
    Hamster.logger.error "#{error} | #{error.backtrace}"
    Hamster.report(to: SLACK_ID, message: "##{Hamster.project_number} | #{error}", use: :both)
  end
end
