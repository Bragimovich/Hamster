# frozen_string_literal: true
require_relative '../lib/kansas_campaign_finance'

def scrape(options)
  case options[:step]
  when 'main'
    scraper = KansasCampaignFinanceScrape.new
    scraper.scrape_part(options[:type], options[:date])
  when 'parse'
    scraper = KansasCampaignFinanceScrape.new
    scraper.parse_part(options[:type])
  when 'update'
    date = Date.today.to_s

    scraper = KansasCampaignFinanceScrape.new
    scraper.scrape_part('main', date)
    scraper.parse_part('main')
    scraper.scrape_part('not_main', date)
    scraper.parse_part('not_main')
  when 'rename_files'
    scraper = KansasCampaignFinanceScrape.new
    scraper.rename_files(options[:type])
  else
    nil
  end
end
