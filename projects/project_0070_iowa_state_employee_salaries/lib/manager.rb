# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/keeper'
require_relative '../lib/parser'

class Manager < Hamster::Harvester
  def initialize
    super
    @keeper = Keeper.new
  end

  def download
    scraper = Scraper.new
    search_hash = scraper.main_page
    #search_hash[:years].each do |year|
    ["1997","1996","1995","1994","1993"].each do |year|
      search_hash[:departments].each do |department|
        logger.debug(year)
        logger.debug(department)
        content = scraper.send_request(year, department)
        store_to_db(content.body)
        peon.put(file: "employee_salaries_#{year}_#{department}.html", content: content.body) rescue nil
      end
    end
    @keeper.update_delete_status
    clear_all
    @keeper.finish
  end

  def store 
    peon.give_list.sort.each do |file|
      store_to_db(peon.give(file: file))
    end
    @keeper.update_delete_status
    clear(file)
    @keeper.finish
  end

  def store_to_db(file)
    parser = Parser.new(file)
    @keeper.store_salaries(parser.store_data)
  end

  def clear_all
    time = Time.now.strftime("%Y_%m_%d").split('_').join('_')
    trash_folder = "State_Employee_Salaries_#{time}"
    peon.list.each do |file|
      peon.move(file: file, to: trash_folder)
    end
  end

  def clear(file)
    time = Time.now.strftime("%Y_%m_%d").split('_').join('_')
    trash_folder = "State_Employee_Salaries_#{time}"
    peon.move(file: file, to: trash_folder)
  end
end
