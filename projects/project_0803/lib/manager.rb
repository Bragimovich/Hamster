# frozen_string_literal: true

require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'

class Manager < Hamster::Harvester

  MAIN_URL = 'https://data.bls.gov/cgi-bin/cpicalc.pl'

  def initialize(**params)
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @run_id = keeper.run_id
  end

  def main
    year_array = (1913..Date.today.year).to_a
    base_year_array = (2018..Date.today.year).to_a
    base_year_array.each do |base_year|
      year_array.each do |year|
        response = scraper.search_request(base_year, year)
        response_req_body = scraper.set_search_form_data(base_year, year)
        parsed_page = parser.parse_html(response.body)
        data_hash = parser.get_data_hash(parsed_page, base_year, year, response_req_body, run_id)
        keeper.insert_data(data_hash)
      end
    end
    keeper.mark_deleted
    keeper.finish
    logger.info "******** Store Done *******"
  end

  private 

  attr_accessor :keeper, :scraper, :run_id, :parser

end

