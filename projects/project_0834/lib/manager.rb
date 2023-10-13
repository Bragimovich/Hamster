# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  def initialize
    super
    @keeper = Keeper.new
  end

  def download
    scraper = Scraper.new
    inmates_arr = scraper.main_page
    inmates_arr.each do |inmate|
      retries = 0
      begin
        parser = Parser.new(scraper.details_page(inmate["intakeNum"]))
        @logger.debug(inmate["intakeNum"])
        hash = parser.parse_inmate
        @logger.debug(hash)
      rescue => e
        @logger.debug(e.full_message)
        retries += 1
        retry if retries < 5
      end
      unless hash.nil?
        hash.merge!(booking_number: inmate["intakeNum"] )
        @keeper.url = "https://centralmagistrate.bexar.org/Home/Details/#{inmate["intakeNum"]}"
        @keeper.data_hash = hash
        @keeper.store_inmate
        @keeper.store_inmate_ids
        @keeper.store_arrests
        @keeper.store_arrests_additional
        @keeper.store_charges
        @keeper.store_bonds
      end
    end
    @keeper.update_delete_status
    @keeper.finish
  end
end
