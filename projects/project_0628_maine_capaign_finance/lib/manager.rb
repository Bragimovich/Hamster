# frozen_string_literal: true
require_relative '../lib/scraper_v3'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  FRANK_RAO = 'U04MHBRVB6F'
  attr_accessor :parser, :keeper
  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
  end
  
  def download(year)
    scraper = ScraperV3.new
    scraper.download_csv(year)
  end
  
  def store(year)
    scraper = ScraperV3.new
    csv_content = scraper.get_csv("CON", year)
    keeper.store_contributions_csv(csv_content, year)
    csv_content = scraper.get_csv("EXP", year)
    keeper.store_expenditures_csv(csv_content, year)
    
    store_transaction_json(year)
    store_candidates_json(year)
    store_committees_json(year)
  end

  def clear_files(year)
    scraper = ScraperV3.new
    scraper.clear_files(year)
  end

  def store_transaction_json(year)
    scraper = ScraperV3.new
    page = 1

    while true
      retries = 10
      begin
        tran_obj = scraper.get_transaction_json(year, "CON", page, 100)
      rescue Exception => e
        retries -= 1
        retry if retries > 0
      end
      break if tran_obj.empty?
      keeper.store_contributions_json(tran_obj)
      logger.debug "CON, Year #{year}, Page #{page}"
      page += 1
    end

    page = 1
    while true
      retries = 10
      begin
        tran_obj = scraper.get_transaction_json(year, "EXP", page, 100)
      rescue Exception => e
        retries -= 1
        retry if retries > 0
      end
      break if tran_obj.empty?
      keeper.store_expenditures_json(tran_obj)
      logger.debug "EXP, Year #{year}, Page #{page}"
      page += 1
    end
  end

  def store_candidates_json(year)
    scraper = ScraperV3.new
    page = 1
    while true
      retries = 10
      begin
        tran_obj = scraper.get_candidates_json(year, page, 100)
      rescue Exception => e
        retries -= 1
        retry if retries > 0
      end
      break if tran_obj.empty?
      keeper.store_candidates_json(tran_obj)
      logger.debug "Candidates,  Year #{year}, Page #{page}"
      page += 1
    end
  end

  def store_committees_json(year)
    scraper = ScraperV3.new
    page = 1
    while true
      retries = 10
      begin
        tran_obj = scraper.get_committees_json(year, page, 100)
      rescue Exception => e
        retries -= 1
        retry if retries > 0
      end
      break if tran_obj.empty?
      keeper.store_committees_json(tran_obj)
      logger.debug "Committees, Year #{year}, Page #{page}"
      page += 1
    end
  end

end
