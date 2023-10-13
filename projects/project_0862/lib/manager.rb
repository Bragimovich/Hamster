# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  def initialize(options)
    super
    @keeper = Keeper.new
    @parser = Parser.new
    @letters_arr = ("A".."Z").map { |item| ("A".."Z").map {|el| item + el} }.flatten
    @let_arr = ("A".."Z").map { |item| item }.flatten
    if options[:single].nil?
      part  = @let_arr.size / options[:instances] + 1
      @let_arr = @let_arr[(options[:instance] * part)...((options[:instance] + 1) * part)]
    end
  end

  def download(options)
    scraper = Scraper.new(options)
    @let_arr.each do |let_first|
      @letters_arr.each do |let_last|
        retries = 0
        main_arr = []
        begin
          scraper.swap_proxy
          main_page_params = @parser.parse_main_page(scraper.main_page)
          search_page = scraper.search_page(main_page_params, let_first, let_last )
          search_page_params = @parser.parse_main_page(search_page)
          list = @parser.parse_list(search_page)
          if !list.empty?
            list.each do |value|
              @logger.info("#{let_first}: #{let_last}")
              @parser.parse_page(scraper.view_inmate(value, search_page_params))
              scraper.swap_proxy
              @keeper.data_hash = @parser.data_hash
              @keeper.store_inmate
              @keeper.store_additional_info
              @keeper.store_inmate_ids
              @keeper.store_arrests
              @keeper.store_arrests_additional
              @keeper.store_charge
              @keeper.store_charge_additional
              @keeper.store_bonds
              @keeper.store_court_hearings
              @keeper.store_holding_facilities
              @keeper.store_facilities_additional
            end
          elsif !@parser.check_page(search_page)
            @parser.parse_page(search_page)
            @keeper.data_hash = @parser.data_hash
            @keeper.store_inmate
            @keeper.store_additional_info
            @keeper.store_inmate_ids
            @keeper.store_arrests
            @keeper.store_arrests_additional
            @keeper.store_charge
            @keeper.store_charge_additional
            @keeper.store_bonds
            @keeper.store_court_hearings
            @keeper.store_holding_facilities
            @keeper.store_facilities_additional
          end
        rescue => e
          @logger.error(e.full_message)
          retries += 1
          retry if retries < 5
        end
      end
    end
    @keeper.update_delete_status
    @keeper.finish
  end
end
