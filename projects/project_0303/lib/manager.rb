require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  SLACK_ID = 'Eldar Eminov'
  def initialize(**params)
    super
    @keeper = Keeper.new
  end

  def download
    scraper = Scraper.new(keeper)
    scraper.scrape
    Hamster.logger.info "##{Hamster.project_number} scraped #{scraper.count} news"
  rescue => error
    Hamster.logger.error "#{error} | #{error.backtrace}"
    Hamster.report(to: SLACK_ID, message: "##{Hamster.project_number} | #{error}", use: :both)
  end

  def store
    files = peon.give_list
    files.each do |file|
      html    = peon.give(file: file)
      parser  = Parser.new(html: html)
      article = parser.parse
      keeper.save_article(article)
    end
    Hamster.logger.info "##{Hamster.project_number} parsed #{keeper.count} news"
  rescue => error
    Hamster.logger.error "#{error} | #{error.backtrace}"
    Hamster.report(to: SLACK_ID, message: "##{Hamster.project_number} | #{error}", use: :both)
  end

  private

  attr_reader :keeper
end

