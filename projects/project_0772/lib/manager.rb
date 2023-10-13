# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  
  WILLIAM_DEVRIES = 'U04JLLPDLPP'
  
  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
  end
  
  def download_and_store(year)
    Hamster.report(to: WILLIAM_DEVRIES, message: "#{@project_number}:\nStarted downloading and storing! ", use: :slack)
    scraper = Scraper.new
    links = scraper.get_detail_link(year)
    links.each do |link|
      if link[:data_type] == 'compensation'
        scraper.landing_page(link[:href])
        data_arr = parser.parse_compensation_data(scraper.get_doc)
      end
      if link[:data_type] == 'expenditures'
        scraper.landing_page(link[:href])
        data_arr = parser.parse_expenditures_data(scraper.get_doc)
      end
      options = {fiscal_year: year, data_source_url: 'https://uasys.edu/system-office/open-checkbook/'}
      keeper.store_data(data_arr, ArHigherEdSalaries, options)
      ## Continiously store data by scrolling down
      while scraper.go_scroll_down
        if link[:data_type] == 'compensation'
          data_arr = parser.parse_compensation_data(scraper.get_doc)
        end
        if link[:data_type] == 'expenditures'
          data_arr = parser.parse_expenditures_data(scraper.get_doc)
        end
        options = {fiscal_year: year, data_source_url: 'https://uasys.edu/system-office/open-checkbook/'}
        keeper.store_data(data_arr, ArHigherEdSalaries, options)
      end
    end
    keeper.finish(year)
    scraper.close_browser
    Hamster.report(to: WILLIAM_DEVRIES, message: "#{@project_number}:\nFinished downloading and storing! ", use: :slack)
  end

  def re_generate_md5_hash
    keeper.re_generate_md5_hash
  end

  def reset_amount_paid
    keeper.reset_amount_paid
  end
  private
    attr_accessor :keeper, :parser

end
