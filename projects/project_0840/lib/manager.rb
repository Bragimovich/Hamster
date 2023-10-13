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
    ('A'..'Z').each do |char|
      scraper = Scraper.new
      begin
        scraper.main_page
        pp captcha = scraper.valid_captcha
        raise "Invalid Captcha" if captcha["captchaMatched"] == false
      rescue => e
        @logger.debug(e.message)
        retry if e.message == "Invalid Captcha"
      end
      @logger.info("Letter: #{char}")
      @logger.debug("Letter: #{char}")
      offenders = scraper.search_page(captcha["captchaKey"], char)
      view_key = offenders["offenderViewKey"]
      captcha_key = offenders["captchaKey"]
      @logger.debug("Count: #{offenders["offenders"].count}")
      offenders["offenders"].each_with_index do |arrest, index|
        @logger.debug("Letter: #{char}, count: #{index}")
        @logger.debug(arrest["arrestNo"])
        @logger.info("Letter: #{char}, count: #{index}")
        @logger.info(arrest["arrestNo"])
        hash = scraper.get_inmate(arrest["arrestNo"], view_key, captcha_key)
        image = scraper.get_image(arrest["arrestNo"])
        hash.merge!({img: image["imageBase"]}) unless image["imageBase"].empty?
        parser = Parser.new(hash)
        @keeper.data_hash = parser.parse_info
        @keeper.store_inmate
        @keeper.store_additional_info
        @keeper.store_arrests
        @keeper.store_charges
        @keeper.store_bonds
        @keeper.store_court_hearings
        @keeper.store_mugshots
      end
    end
    @keeper.update_delete_status
    @keeper.finish
  end
end
