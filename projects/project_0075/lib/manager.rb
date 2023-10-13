# Scraper name: Seth Putz
# Date: 2023-01-12
# frozen_string_literal: true

require_relative '../lib/keeper'
require_relative '../lib/scraper'
require_relative '../lib/parser'



class BuildingPermitsManager < Hamster::Harvester
  SLACK_ID  = 'seth.putz'.freeze
  DAY = 86400
  TEN_MINUTES = 600
  FIVE_MINUTES = 300


  def start_download
    scraper = BuildingPermitsScraper.new
    loop do
      begin
        scraper.download
        logger.debug 'went to sleep'
        sleep(DAY)
      rescue => e
        logger.debug 'inside rescue'
        logger.debug e.full_message
        Hamster.report(to: 'seth.putz', message: "Project # 0075 --download: Error - \n#{e}, went to sleep for 10 min", use: :both)
        sleep(TEN_MINUTES)
      end
    end
  end

  def start_store
    parser = BuildingPermitsParser.new
    scraper = BuildingPermitsScraper.new
    loop do
      begin
        scraper.store(parser)
        logger.debug 'went to sleep'
        sleep(DAY)
      rescue => e
        logger.debug 'inside rescue'
        logger.debug e.full_message
        Hamster.report(to: 'seth.putz', message: "Project # 0075 --store: Error - \n#{e}, went to sleep for 10 min", use: :both)
        sleep(TEN_MINUTES)
      end
    end
  end

# Does what both "start_download" and "start_store" do, with no manual assistance it downloads and inserts any new data in the mySQL table.

  def start_cron_update
    scraper = BuildingPermitsScraper.new
    scraper.cron
  end


  private

  def report_success(message)
    puts message.green
    Hamster.report(to: SLACK_ID, message: message, use: :both)
  end
end
